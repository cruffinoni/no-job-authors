using Verse;

namespace NoJobAuthors;

public sealed class NoJobAuthorsSettings : ModSettings
{
    public bool onlyApplyToNonQualityItems;

    public override void ExposeData()
    {
        Scribe_Values.Look(ref onlyApplyToNonQualityItems, "onlyApplyToNonQualityItems", false);
    }
}
