using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Reflection.Emit;
using HarmonyLib;
using RimWorld;
using Verse;
using Verse.AI;

namespace NoJobAuthors;

[StaticConstructorOnStartup]
public static class Initialization
{
    static Initialization()
    {
        try
        {
            new Harmony("Doug.NoJobAuthors").PatchAll();
            Log.Message("No Job Authors initialized");
        }
        catch (Exception e)
        {
            Log.Error($"No Job Authors failed to initialize: {e}");
            throw;
        }
    }
}

[HarmonyPatch(typeof(WorkGiver_DoBill), "ClosestUnfinishedThingForBill")]
public static class WorkGiver_DoBill_ClosestUnfinishedThingForBill_Patch
{
    [HarmonyPrefix]
    public static bool ClosestUnfinishedThingForBill(ref UnfinishedThing __result, Pawn pawn,
        Bill_ProductionWithUft bill)
    {
        bool Validator(Thing t)
        {
            return !t.IsForbidden(pawn) &&
                   ((UnfinishedThing)t).Recipe == bill.recipe &&
                   ((UnfinishedThing)t).ingredients.TrueForAll(x => bill.IsFixedOrAllowedIngredient(x.def)) &&
                   pawn.CanReserve(t);
        }

        var thingReq = ThingRequest.ForDef(bill.recipe.unfinishedThingDef);
        var traverseParams = TraverseParms.For(pawn, pawn.NormalMaxDanger());

        __result = (UnfinishedThing)GenClosest.ClosestThingReachable(
            pawn.Position,
            pawn.Map,
            thingReq,
            PathEndMode.InteractionCell,
            traverseParams,
            validator: Validator);
        return false;
    }
}

[HarmonyPatch(typeof(UnfinishedThing), "get_Creator")]
public static class UnfinishedThing_GetCreator_Patch
{
    [HarmonyPrefix]
    public static bool Creator(ref Pawn __result)
    {
        __result = null;
        return false;
    }
}

[HarmonyPatch(typeof(UnfinishedThing), "set_Creator")]
public static class UnfinishedThing_SetCreator_Patch
{
    private static readonly AccessTools.FieldRef<UnfinishedThing, string> CreatorName =
        AccessTools.FieldRefAccess<UnfinishedThing, string>("creatorName");

    [HarmonyPostfix]
    public static void Creator(UnfinishedThing __instance)
    {
        CreatorName(__instance) = "NoJobAuthors_Anyone".TranslateSimple();
    }
}

[HarmonyPatch(typeof(WorkGiver_DoBill), "StartOrResumeBillJob")]
public static class WorkGiver_DoBill_StartOrResumeBillJob_Patch
{
    private static readonly MethodInfo BoundWorkerGetter =
        AccessTools.PropertyGetter(typeof(Bill_ProductionWithUft), "BoundWorker");

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
    public static IEnumerable<CodeInstruction> StartOrResumeBillJob(IEnumerable<CodeInstruction> instructions)
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

        for (var offset = 0; offset < 4; offset++)
        {
            code[lastMatchPosition + offset].opcode = OpCodes.Nop;
            code[lastMatchPosition + offset].operand = null;
        }

        Log.Message("No Job Authors transpiler patched StartOrResumeBillJob (1 bound-worker check site).");
        return code;
    }
}

[HarmonyPatch(typeof(WorkGiver_DoBill), "FinishUftJob")]
public static class WorkGiver_DoBill_FinishUftJob_Patch
{
    private static readonly MethodInfo UnfinishedThingCreatorGetter =
        AccessTools.PropertyGetter(typeof(UnfinishedThing), "Creator");

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
        var originalBranchOpcode = code[start + 3].opcode;
        var branchTarget = code[start + 3].operand;
        if (branchTarget == null)
            throw new InvalidOperationException(
                "No Job Authors transpiler drift in FinishUftJob: creator check branch operand was null.");

        for (var offset = 0; offset < 3; offset++)
        {
            code[start + offset].opcode = OpCodes.Nop;
            code[start + offset].operand = null;
        }

        code[start + 3].opcode = originalBranchOpcode == OpCodes.Beq ? OpCodes.Br : OpCodes.Br_S;
        code[start + 3].operand = branchTarget;

        Log.Message("No Job Authors transpiler patched FinishUftJob (1 creator-check site).");
        return code;
    }
}