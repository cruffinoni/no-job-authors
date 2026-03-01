using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Reflection.Emit;
using HarmonyLib;
using RimWorld;
using Verse;

namespace NoJobAuthors;

[HarmonyPatch(typeof(WorkGiver_DoBill), "FinishUftJob")]
public static class WorkGiver_DoBill_FinishUftJob_Patch
{
    private static readonly MethodInfo UnfinishedThingCreatorGetter =
        AccessTools.PropertyGetter(typeof(UnfinishedThing), "Creator");
    private static readonly MethodInfo ShouldBypassAuthorship =
        AccessTools.Method(typeof(AuthorshipPolicy), nameof(AuthorshipPolicy.ShouldBypassAuthorship),
            new[] { typeof(UnfinishedThing) });

    private static bool IsCreatorMatchBranch(OpCode opcode)
    {
        return opcode == OpCodes.Beq || opcode == OpCodes.Beq_S;
    }

    [HarmonyTranspiler]
    public static IEnumerable<CodeInstruction> FinishUftJob(IEnumerable<CodeInstruction> instructions)
    {
        var code = instructions.ToList();
        var matcher = new CodeMatcher(code).Start();
        var matchPositions = new List<int>();

        while (true)
        {
            matcher.MatchStartForward(
                new CodeMatch(OpCodes.Ldarg_1),
                new CodeMatch(ci => ci.Calls(UnfinishedThingCreatorGetter)),
                new CodeMatch(OpCodes.Ldarg_0),
                new CodeMatch(ci => IsCreatorMatchBranch(ci.opcode)));
            if (matcher.IsInvalid)
                break;

            matchPositions.Add(matcher.Pos);
            matcher.Advance(1);
        }

        if (matchPositions.Count != 1)
            throw new InvalidOperationException(
                $"No Job Authors transpiler drift in FinishUftJob: expected 1 creator-check match, found {matchPositions.Count}.");

        var start = matchPositions[0];
        var branchTarget = code[start + 3].operand;
        if (branchTarget == null)
            throw new InvalidOperationException(
                "No Job Authors transpiler drift in FinishUftJob: creator check branch operand was null.");

        var injected = new List<CodeInstruction>
        {
            new(OpCodes.Ldarg_1),
            new(OpCodes.Call, ShouldBypassAuthorship),
            new(OpCodes.Brtrue, branchTarget)
        };
        code.InsertRange(start, injected);

        Log.Message("No Job Authors transpiler patched FinishUftJob (1 creator-check site, conditional bypass).");
        return code;
    }
}
