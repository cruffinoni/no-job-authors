using System;
using RimWorld;
using Verse;

namespace NoJobAuthors;

public static class AuthorshipPolicy
{
    private static readonly Type CompQualityType = typeof(CompQuality);

    public static bool ShouldBypassAuthorship(Bill_ProductionWithUft bill)
    {
        return ShouldBypassAuthorship(bill?.recipe);
    }

    public static bool ShouldBypassAuthorship(UnfinishedThing unfinishedThing)
    {
        return ShouldBypassAuthorship(unfinishedThing?.Recipe);
    }

    private static bool ShouldBypassAuthorship(RecipeDef recipe)
    {
        if (!NoJobAuthorsMod.Settings.onlyApplyToNonQualityItems)
            return true;

        return !RecipeHasQuality(recipe);
    }

    private static bool RecipeHasQuality(RecipeDef recipe)
    {
        if (recipe == null)
            return true;

        var foundAnyProductDef = false;
        if (recipe.products != null)
        {
            foreach (var product in recipe.products)
            {
                var thingDef = product?.thingDef;
                if (thingDef == null)
                    continue;

                foundAnyProductDef = true;
                if (thingDef.HasComp(CompQualityType))
                    return true;
            }
        }

        var producedThingDef = recipe.ProducedThingDef;
        if (producedThingDef != null)
        {
            foundAnyProductDef = true;
            if (producedThingDef.HasComp(CompQualityType))
                return true;
        }

        return !foundAnyProductDef;
    }
}
