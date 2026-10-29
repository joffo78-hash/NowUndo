-- Script : basculer (ouvrir/fermer) la fenêtre flottante de l'effet à un index spécifié sur la PISTE 2
-- Indice de l'effet (0 = premier effet)

local fx_index = 0

-- ⚠️ MODIFICATION : piste 2 au lieu de la piste sélectionnée
local track = reaper.GetTrack(0, 15)   -- index 1 = piste 2
if not track then
    reaper.ShowMessageBox("La piste 2 n'existe pas", "Erreur", 0)
    return
end

local fx_count = reaper.TrackFX_GetCount(track)
if fx_index >= fx_count then
    reaper.ShowMessageBox("La piste 2 ne possède pas d'effet à cet index", "Erreur", 0)
    return
end

-- Déterminer si la fenêtre est actuellement ouverte
-- Priorité à TrackFX_GetFloatingWindow (plus fiable), sinon utiliser TrackFX_GetOpen
local is_open = false
if reaper.TrackFX_GetFloatingWindow(track, fx_index) then
    is_open = true
elseif reaper.TrackFX_GetOpen(track, fx_index) then
    is_open = true
end

if is_open then
    -- === Fermer ===
    -- Première tentative : SetOpen
    reaper.TrackFX_SetOpen(track, fx_index, false)
    
    -- Vérifier si c'est vraiment fermé, sinon essayer Show(...,2)
    if reaper.TrackFX_GetFloatingWindow(track, fx_index) then
        reaper.TrackFX_Show(track, fx_index, 2)
    end
    
    -- Si toujours ouvert (cas particulier de certains plugins), utiliser l'astuce fermer+rouvrir puis refermer
    if reaper.TrackFX_GetFloatingWindow(track, fx_index) then
        reaper.TrackFX_Show(track, fx_index, 2)
        reaper.TrackFX_Show(track, fx_index, 3)
        reaper.TrackFX_Show(track, fx_index, 2)
    end
else
    -- === Ouvrir ===
    reaper.TrackFX_Show(track, fx_index, 3)
end

-- Rafraîchir l'affichage de la chaîne d'effets de la piste
reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()
