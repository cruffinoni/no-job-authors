using HarmonyLib;
using RimWorld;
using Verse;
using Verse.AI;

namespace NoJobAuthors;

[HarmonyPatch(typeof(WorkGiver_DoBill), "ClosestUnfinishedThingForBill")]
public static class WorkGiver_DoBill_ClosestUnfinishedThingForBill_Patch
{
    [HarmonyPrefix]
    public static bool ClosestUnfinishedThingForBill(ref UnfinishedThing __result, Pawn pawn,
        Bill_ProductionWithUft bill)
    {
        if (!AuthorshipPolicy.ShouldBypassAuthorship(bill))
            return true;

        if (bill?.recipe?.unfinishedThingDef == null)
            return true;

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
