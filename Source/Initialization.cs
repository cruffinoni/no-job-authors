using System;
using HarmonyLib;
using Verse;

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
