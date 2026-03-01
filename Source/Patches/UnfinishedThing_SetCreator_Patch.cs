using HarmonyLib;
using Verse;

namespace NoJobAuthors;

[HarmonyPatch(typeof(UnfinishedThing), "set_Creator")]
public static class UnfinishedThing_SetCreator_Patch
{
    private static readonly AccessTools.FieldRef<UnfinishedThing, string> CreatorName =
        AccessTools.FieldRefAccess<UnfinishedThing, string>("creatorName");

    [HarmonyPostfix]
    public static void Creator(UnfinishedThing __instance)
    {
        if (!AuthorshipPolicy.ShouldBypassAuthorship(__instance))
            return;

        CreatorName(__instance) = "NoJobAuthors_Anyone".TranslateSimple();
    }
}
