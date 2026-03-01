using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Reflection.Emit;
using HarmonyLib;
using RimWorld;
using Verse;

namespace NoJobAuthors;

[HarmonyPatch(typeof(WorkGiver_DoBill), "StartOrResumeBillJob")]
public static class WorkGiver_DoBill_StartOrResumeBillJob_Patch
{
    private static readonly MethodInfo BoundWorkerGetter =
        AccessTools.PropertyGetter(typeof(Bill_ProductionWithUft), "BoundWorker");
    private static readonly MethodInfo ShouldBypassAuthorship =
        AccessTools.Method(typeof(AuthorshipPolicy), nameof(AuthorshipPolicy.ShouldBypassAuthorship),
            new[] { typeof(Bill_ProductionWithUft) });

    private static bool IsBoundWorkerMismatchBranch(OpCode opcode)
    {
        return opcode == OpCodes.Bne_Un || opcode == OpCodes.Bne_Un_S;
    }

    private static bool IsLoadLocal(OpCode opcode)
    {
        return opcode == OpCodes.Ldloc || opcode == OpCodes.Ldloc_S ||
               opcode == OpCodes.Ldloc_0 || opcode == OpCodes.Ldloc_1 ||
               opcode == OpCodes.Ldloc_2 || opcode == OpCodes.Ldloc_3;
    }

    [HarmonyTranspiler]
    public static IEnumerable<CodeInstruction> StartOrResumeBillJob(IEnumerable<CodeInstruction> instructions,
        ILGenerator generator)
    {
        var code = instructions.ToList();
        var matcher = new CodeMatcher(code).Start();
        var matchPositions = 0;
        var lastMatchPosition = -1;

        while (true)
        {
            matcher.MatchStartForward(
                new CodeMatch(ci => IsLoadLocal(ci.opcode)),
                new CodeMatch(ci => ci.Calls(BoundWorkerGetter)),
                new CodeMatch(OpCodes.Ldarg_1),
                new CodeMatch(ci => IsBoundWorkerMismatchBranch(ci.opcode)));
            if (matcher.IsInvalid)
                break;

            matchPositions++;
            lastMatchPosition = matcher.Pos;
            matcher.Advance(1);
        }

        if (matchPositions != 1)
            throw new InvalidOperationException(
                $"No Job Authors transpiler drift in StartOrResumeBillJob: expected 1 bound-worker check match, found {matchPositions}.");

        if (lastMatchPosition + 4 >= code.Count)
            throw new InvalidOperationException(
                "No Job Authors transpiler drift in StartOrResumeBillJob: bound-worker check did not have a fallthrough instruction.");

        var skipBoundWorkerCheckLabel = generator.DefineLabel();
        code[lastMatchPosition + 4].labels.Add(skipBoundWorkerCheckLabel);

        var originalBillLoad = code[lastMatchPosition];
        var injected = new List<CodeInstruction>
        {
            new(originalBillLoad.opcode, originalBillLoad.operand),
            new(OpCodes.Call, ShouldBypassAuthorship),
            new(OpCodes.Brtrue, skipBoundWorkerCheckLabel)
        };
        code.InsertRange(lastMatchPosition, injected);

        Log.Message(
            "No Job Authors transpiler patched StartOrResumeBillJob (1 bound-worker check site, conditional bypass).");
        return code;
    }
}
