using UnityEngine;
using Verse;

namespace NoJobAuthors;

public sealed class NoJobAuthorsMod : Mod
{
    public static NoJobAuthorsSettings Settings { get; private set; } = new();

    public NoJobAuthorsMod(ModContentPack content) : base(content)
    {
        Settings = GetSettings<NoJobAuthorsSettings>();
    }

    public override string SettingsCategory()
    {
        return "No Job Authors";
    }

    public override void DoSettingsWindowContents(Rect inRect)
    {
        var listing = new Listing_Standard();
        listing.Begin(inRect);
        listing.CheckboxLabeled(
            "NoJobAuthors_Settings_OnlyNonQuality".Translate(),
            ref Settings.onlyApplyToNonQualityItems,
            "NoJobAuthors_Settings_OnlyNonQuality_Desc".Translate());
        listing.End();
    }
}
