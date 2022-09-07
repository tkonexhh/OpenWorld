/*
Shader Control - (C) Copyright 2016-2019 Ramiro Oliva (Kronnect)
*/

using UnityEngine;
using UnityEditor;
using System;
using System.Text;

namespace ShaderControl {

    public enum BuildViewSortType {
        ShaderName = 0,
        ShaderKeywordCount = 1,
        Keyword = 2
    }

    public partial class SCWindow : EditorWindow {

        string buildShaderNameFilter;
        StringBuilder sb = new StringBuilder();

        void DrawBuildGUI() {

            GUILayout.Box(new GUIContent("This tab shows all shaders compiled in your last build.\nHere you can exclude any number of shaders or keywords from future compilations. No file is modified, only excluded from the build.\nIf you have exceeded the maximum allowed keywords in your project, use the <b>Project View</b> tab to remove shaders or disable any unwanted keyword from the project."), titleStyle, GUILayout.ExpandWidth(true));
            EditorGUILayout.Separator();

            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button(new GUIContent("Quick Build", "Forces a quick compilation to extract all shaders and keywords included in the build."))) {
                EditorUtility.DisplayDialog("Ready to analyze!", "Now make a build as normal (select 'File -> Build Settings -> Build').\n\nShader Control will detect the shaders and keywords from the build process and list that information here.\n\nImportant Note!\nTo make this special build faster, shaders won't be compiled (they will show in pink in the build). This is normal. To create a normal build, just build the project again without clicking 'Quick Build'.", "Ok");
                SetEditorPrefBool("QUICK_BUILD", true);
                nextQuickBuild = true;
                ClearBuildData();
            }
            if (GUILayout.Button("Help", GUILayout.Width(40))) {
                ShowHelpWindowBuildView();
            }
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.EndVertical();

            if (nextQuickBuild) {
                EditorGUILayout.HelpBox("Shader Control is ready to collect data during the next build.", MessageType.Info);
            }

            int shadersCount = shadersBuildInfo == null || shadersBuildInfo.shaders == null ? 0 : shadersBuildInfo.shaders.Count;

            if (shadersBuildInfo != null) {
                if (!nextQuickBuild) {
                    EditorGUILayout.LabelField("Last build: " + ((shadersBuildInfo.creationDateTicks != 0) ? shadersBuildInfo.creationDateString : "no data yet. Click 'Quick Build' for more details."), EditorStyles.boldLabel);
                }
                if (shadersBuildInfo.requiresBuild) {
                    EditorGUILayout.HelpBox("Project shaders have been modified. Do a 'Quick Build' again to ensure the data shown in this tab is accurate.", MessageType.Warning);
                }
            }

            if (shadersCount == 0) return;

            if (totalBuildShaders == 0 || totalBuildIncludedShaders == 0 || totalBuildKeywords == 0 || (totalBuildKeywords == totalBuildIncludedKeywords && totalBuildShaders == totalBuildIncludedShaders)) {
                EditorGUILayout.HelpBox("Total Compiled Shaders: " + totalBuildShaders + "  Shaders Using Keywords: " + totalBuildShadersWithKeywords + "\nTotal Unique Keywords: " + totalBuildKeywords, MessageType.Info);
            } else {
                int shadersPerc = totalBuildIncludedShaders * 100 / totalBuildShaders;
                int shadersWithKeywordsPerc = totalBuildIncludedShadersWithKeywords * 100 / totalBuildIncludedShaders;
                int keywordsPerc = totalBuildIncludedKeywords * 100 / totalBuildKeywords;
                EditorGUILayout.HelpBox("Total Compiled Shaders: " + totalBuildIncludedShaders + " of " + totalBuildShaders + " (" + shadersPerc + "%" + "  Shaders Using Keywords: " + totalBuildIncludedShadersWithKeywords + " of " + totalBuildShadersWithKeywords + " (" + shadersWithKeywordsPerc + "%)\nTotal Unique Keywords: " + totalBuildIncludedKeywords + " of " + totalBuildKeywords + " (" + keywordsPerc.ToString() + "%)", MessageType.Info);
            }

            EditorGUILayout.Separator();

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Sort By", GUILayout.Width(100));
            EditorGUI.BeginChangeCheck();
            shadersBuildInfo.sortType = (BuildViewSortType)EditorGUILayout.EnumPopup(shadersBuildInfo.sortType);
            if (EditorGUI.EndChangeCheck()) {
                if (shadersBuildInfo != null) {
                    shadersBuildInfo.Resort();
                }
                EditorUtility.SetDirty(shadersBuildInfo);
                GUIUtility.ExitGUI();
                return;
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Shader Name", GUILayout.Width(100));
            buildShaderNameFilter = EditorGUILayout.TextField(buildShaderNameFilter);
            if (GUILayout.Button(new GUIContent("Clear", "Clear filter."), EditorStyles.miniButton, GUILayout.Width(60))) {
                buildShaderNameFilter = "";
                GUIUtility.keyboardControl = 0;
            }
            EditorGUILayout.EndHorizontal();

            if (shadersBuildInfo.sortType != BuildViewSortType.Keyword) {
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("Keywords >=", GUILayout.Width(100));
                minimumKeywordCount = EditorGUILayout.IntSlider(minimumKeywordCount, 0, maxBuildKeywordsCountFound);
                EditorGUILayout.EndHorizontal();
            }
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Keyword Filter", GUILayout.Width(100));
            keywordFilter = EditorGUILayout.TextField(keywordFilter);
            if (GUILayout.Button(new GUIContent("Clear", "Clear filter."), EditorStyles.miniButton, GUILayout.Width(60))) {
                keywordFilter = "";
                GUIUtility.keyboardControl = 0;
            }
            EditorGUILayout.EndHorizontal();

            if (shadersBuildInfo.sortType != BuildViewSortType.Keyword) {
                shadersBuildInfo.hideReadOnlyShaders = EditorGUILayout.ToggleLeft("Hide read-only/internal shaders", shadersBuildInfo.hideReadOnlyShaders);
            }

            EditorGUILayout.Separator();

            scrollViewPosProject = EditorGUILayout.BeginScrollView(scrollViewPosProject);

            bool requireUpdate = false;
            bool needsTitle = true;

            if (shadersBuildInfo.sortType == BuildViewSortType.Keyword) {
                if (buildKeywordView != null) {
                    int kvCount = buildKeywordView.Count;
                    for (int s = 0; s < kvCount; s++) {
                        BuildKeywordView kwv = buildKeywordView[s];
                        string keyword = kwv.keyword;
                        if (!string.IsNullOrEmpty(keywordFilter) && keyword.IndexOf(keywordFilter, StringComparison.InvariantCultureIgnoreCase) < 0)
                            continue;


                        if (needsTitle) {
                            needsTitle = false;
                            GUILayout.Label("Used keywords:");
                        }

                        int kvShadersCount = kwv.shaders.Count;

                        sb.Length = 0;
                        sb.Append("Keyword #");
                        sb.Append(s + 1);
                        sb.Append(" <b>");
                        sb.Append(kwv.keyword);
                        sb.Append("</b> found in ");
                        sb.Append(kvShadersCount);
                        sb.Append(" shader(s)");
                        EditorGUILayout.BeginHorizontal();
                        kwv.foldout = EditorGUILayout.Foldout(kwv.foldout, new GUIContent(sb.ToString()), foldoutRTF);

                        if (!kwv.isInternal && GUILayout.Button("Show In Project View", EditorStyles.miniButton, GUILayout.Width(160))) {
                            sortType = SortType.EnabledKeywordsCount;
                            projectShaderNameFilter = "";
                            keywordFilter = kwv.keyword;
                            keywordScopeFilter = KeywordScopeFilter.Any;
                            pragmaTypeFilter = PragmaTypeFilter.Any;
                            scanAllShaders = true;
                            if (shaders == null) ScanProject();
                            viewMode = ViewMode.Project;
                            GUIUtility.ExitGUI();
                        }

                        EditorGUILayout.EndHorizontal();
                        if (kwv.foldout) {
                            for (int m = 0; m < kvShadersCount; m++) {
                                ShaderBuildInfo sb = kwv.shaders[m];
                                EditorGUILayout.BeginHorizontal();
                                EditorGUILayout.LabelField("", GUILayout.Width(30));
                                EditorGUILayout.LabelField(shaderIcon, GUILayout.Width(18));
                                EditorGUILayout.LabelField(sb.name);
                                if (sb.isInternal) {
                                    GUILayout.Label("(Internal Shader)");
                                } else {
                                    if (GUILayout.Button("Locate", EditorStyles.miniButton, GUILayout.Width(80))) {
                                        PingShader(sb.name);
                                    }
                                    if (GUILayout.Button("Show In Project View", EditorStyles.miniButton, GUILayout.Width(160))) {
                                        projectShaderNameFilter = sb.simpleName;
                                        keywordFilter = "";
                                        keywordScopeFilter = KeywordScopeFilter.Any;
                                        pragmaTypeFilter = PragmaTypeFilter.Any;
                                        scanAllShaders = true;
                                        PingShader(sb.name);
                                        if (shaders == null) ScanProject();
                                        viewMode = ViewMode.Project;
                                        GUIUtility.ExitGUI();
                                    }
                                }
                                EditorGUILayout.EndHorizontal();
                            }
                        }
                    }
                }
            } else {
                for (int k = 0; k < shadersCount; k++) {
                    ShaderBuildInfo sb = shadersBuildInfo.shaders[k];

                    int kwCount = sb.keywords == null ? 0 : sb.keywords.Count;
                    if (kwCount < minimumKeywordCount && minimumKeywordCount > 0) continue;

                    if ((sb.isReadOnly || sb.isInternal) && shadersBuildInfo.hideReadOnlyShaders) continue;
                    if (!string.IsNullOrEmpty(keywordFilter) && !sb.ContainsKeyword(keywordFilter, false))
                        continue;
                    if (!string.IsNullOrEmpty(buildShaderNameFilter) && sb.name.IndexOf(buildShaderNameFilter, StringComparison.InvariantCultureIgnoreCase) < 0) continue;

                    if (needsTitle) {
                        needsTitle = false;
                        GUILayout.Label("Compiled shaders:");
                    }

                    GUI.enabled = sb.includeInBuild;
                    EditorGUILayout.BeginHorizontal();
                    string shaderName = sb.name;
                    if (sb.isInternal) shaderName += " (internal, ";
                    else if (sb.isReadOnly) shaderName += " (read-only, ";
                    else shaderName += " (";

                    sb.isExpanded = EditorGUILayout.Foldout(sb.isExpanded, shaderName + kwCount + " keyword" + (kwCount != 1 ? "s)" : ")"), sb.isInternal ? foldoutDim : foldoutNormal);
                    GUILayout.FlexibleSpace();
                    GUI.enabled = true;
                    if (sb.name != "Standard") {
                        EditorGUI.BeginChangeCheck();
                        sb.includeInBuild = EditorGUILayout.ToggleLeft("Include", sb.includeInBuild, GUILayout.Width(90));
                        if (EditorGUI.EndChangeCheck()) {
                            requireUpdate = true;
                        }
                    }
                    EditorGUILayout.EndHorizontal();
                    if (sb.isExpanded) {
                        GUI.enabled = sb.includeInBuild;
                        EditorGUI.indentLevel++;
                        if (kwCount == 0) {
                            EditorGUILayout.LabelField("No keywords.");
                        } else {
                            if (!sb.isInternal) {
                                EditorGUILayout.BeginHorizontal();
                                EditorGUILayout.LabelField("", GUILayout.Width(15));
                                if (GUILayout.Button("Locate", EditorStyles.miniButton, GUILayout.Width(80))) {
                                    PingShader(sb.name);
                                }
                                if (!sb.isInternal && GUILayout.Button("Show In Project View", EditorStyles.miniButton, GUILayout.Width(160))) {
                                    projectShaderNameFilter = sb.simpleName;
                                    keywordScopeFilter = KeywordScopeFilter.Any;
                                    pragmaTypeFilter = PragmaTypeFilter.Any;
                                    scanAllShaders = true;
                                    PingShader(sb.name);
                                    if (shaders == null) ScanProject();
                                    viewMode = ViewMode.Project;
                                    GUIUtility.ExitGUI();
                                }
                                EditorGUILayout.EndHorizontal();
                            }
                            for (int j = 0; j < kwCount; j++) {
                                KeywordBuildSettings kw = sb.keywords[j];
                                EditorGUILayout.BeginHorizontal();
                                EditorGUILayout.LabelField(kw.keyword);
                                GUILayout.FlexibleSpace();
                                EditorGUI.BeginChangeCheck();
                                kw.includeInBuild = EditorGUILayout.ToggleLeft("Include", kw.includeInBuild, GUILayout.Width(90));
                                if (EditorGUI.EndChangeCheck()) {
                                    requireUpdate = true;
                                }
                                EditorGUILayout.EndHorizontal();
                            }
                        }

                        EditorGUILayout.BeginHorizontal();
                        GUILayout.Space(20);
                        if (GUILayout.Button("Advanced...", GUILayout.Width(120))) {
                            SCShader projectShader = GetShaderByName(sb.name);
                            SCWindowAdvanced.ShowWindow(sb, projectShader);
                        }
                        int variantsCount = sb.variants != null ? sb.variants.Count : 0;
                        if (variantsCount > 0) {
                            GUILayout.Label("(Only building " + variantsCount + " variants)");
                        }
                        EditorGUILayout.EndHorizontal();


                        EditorGUI.indentLevel--;
                    }
                    GUI.enabled = true;
                }
            }
            EditorGUILayout.EndScrollView();

            if (requireUpdate) {
                RefreshBuildStats(true);
                EditorUtility.SetDirty(shadersBuildInfo);
                AssetDatabase.SaveAssets();
            }

        }


    }

}