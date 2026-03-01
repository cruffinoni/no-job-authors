using HarmonyLib;
using Verse;

namespace NoJobAuthors;

[HarmonyPatch(typeof(UnfinishedThing), "get_Creator")]
public static class UnfinishedThing_GetCreator_Patch
{
    [HarmonyPrefix]
    public static bool Creator(UnfinishedThing __instance, ref Pawn __result)
    {
        if (!AuthorshipPolicy.ShouldBypassAuthorship(__instance))
            return true;

        __result = null;
        return false;
    }
}
