
import math, random
_RNG = random.Random(12345)
MEMN = 14000000
GMEMN = 8200000
M = [0.0] * MEMN
GM = [0.0] * GMEMN
_clock = [0.0]
def _tr(x): return x > 0.00001 or x < -0.00001
def _ix(x):
    return int(math.floor(x + 0.00001))
def _mget(x):
    i = int(math.floor(x + 0.00001))
    return M[i] if 0 <= i < MEMN else 0.0
def _mset(i, v):
    if 0 <= i < MEMN: M[i] = v
def _gget(x):
    i = int(math.floor(x + 0.00001))
    return GM[i] if 0 <= i < GMEMN else 0.0
def _gset(i, v):
    if 0 <= i < GMEMN: GM[i] = v
def _div(a, b):
    try: return a / b
    except ZeroDivisionError: return 0.0 if a == 0 else (math.copysign(1e300, a))
def _mod(a, b):
    bi = int(abs(b))
    return float(int(abs(a)) % bi) if bi else 0.0
def _pow(a, b):
    try:
        r = a ** b
        return r.real if isinstance(r, complex) else float(r)
    except (OverflowError, ZeroDivisionError): return 0.0
def _floor(x): return float(math.floor(x))
def _ceil(x): return float(math.ceil(x))
def _round(x): return float(math.floor(x + 0.5))
def _exp(x):
    try: return math.exp(x)
    except OverflowError: return 1e300
def _log(x): return math.log(x) if x > 0 else -1e300
def _log10(x): return math.log10(x) if x > 0 else -1e300
def _sqrt(x): return math.sqrt(abs(x))
def _sign(x): return 1.0 if x > 0 else (-1.0 if x < 0 else 0.0)
def _rand(x=1.0): return _RNG.random() * x
def _time(): return _clock[0]
def _zero(*a): return 0.0
def _memset(d, v, n):
    d = int(d); n = int(n)
    if n <= 0: return d
    a = max(0, d); b = min(MEMN, d + n)
    if b > a: M[a:b] = [v] * (b - a)
    return d
def _memcpy(d, s_, n):
    d = int(d); s_ = int(s_); n = int(n)
    if n <= 0: return d
    M[d:d+n] = M[s_:s_+n]
    return d


v_ab_len = 0.0
v_ab_nb = 0.0
v_ab_ts = 0.0
v_acc_cur = 0.0
v_acc_cur_dirty = 0.0
v_acc_end = 0.0
v_acc_hi = 0.0
v_acc_len = 0.0
v_acc_lo = 0.0
v_acc_mode = 0.0
v_acc_ok = 0.0
v_acc_set0 = 0.0
v_acc_set1 = 0.0
v_acc_size = 0.0
v_acc_wmin = 0.0
v_acc_wrep = 0.0
v_active_control = 0.0
v_active_history_idx = 0.0
v_active_part = 0.0
v_an_after_wp = 0.0
v_an_bj = 0.0
v_an_bs = 0.0
v_an_d = 0.0
v_an_dmin = 0.0
v_an_done = 0.0
v_an_exit_pending = 0.0
v_an_gap = 0.0
v_an_gapm = 0.0
v_an_j = 0.0
v_an_keep = 0.0
v_an_kk = 0.0
v_an_mx_was = 0.0
v_an_n = 0.0
v_an_ne = 0.0
v_an_nr = 0.0
v_an_ns = 0.0
v_an_osub = 0.0
v_an_prev_hist = 0.0
v_an_prev_state = 0.0
v_an_q = 0.0
v_an_r = 0.0
v_an_sc = 0.0
v_an_target = 0.0
v_an_wasg = 0.0
v_an_win_last = 0.0
v_an_win_pend = 0.0
v_an_win_sig = 0.0
v_an_win_t = 0.0
v_an_wrap_pending = 0.0
v_ana_budget = 0.0
v_ana_end = 0.0
v_ana_env = 0.0
v_ana_k = 0.0
v_ana_last_trig = 0.0
v_ana_max_peak = 0.0
v_ana_min_dist = 0.0
v_ana_mode = 0.0
v_ana_win_size = 0.0
v_analysing = 0.0
v_ar_att = 0.0
v_ar_cnt = 0.0
v_ar_dn = 0.0
v_ar_hold = 0.0
v_ar_in = 0.0
v_ar_k = 0.0
v_ar_lp = 0.0
v_ar_rel = 0.0
v_ar_up = 0.0
v_ar_x = 0.0
v_auto_above_prev = 0.0
v_auto_on = 0.0
v_auto_rep_active = 0.0
v_auto_rep_hold_counter = 0.0
v_available_slots = 0.0
v_b_bg = 0.0
v_base = 0.0
v_base_backup_l = 0.0
v_base_backup_r = 0.0
v_base_cloud_center = 0.0
v_base_gt_ms = 0.0
v_base_len_part1 = 0.0
v_base_len_part2 = 0.0
v_base_len_part3 = 0.0
v_base_loop_length = 0.0
v_base_mix_factor = 0.0
v_beat_position = 0.0
v_beats_per_step = 0.0
v_bg_dg = 0.0
v_bg_env = 0.0
v_bg_fr = 0.0
v_bg_fs = 0.0
v_bg_l = 0.0
v_bg_len = 0.0
v_bg_p0 = 0.0
v_bg_p1 = 0.0
v_bg_p2 = 0.0
v_bg_p3 = 0.0
v_bg_r = 0.0
v_bg_rp = 0.0
v_bg_wg = 0.0
v_blk_ms = 0.0
v_br_bg_clk = 0.0
v_br_bg_e = 0.0
v_br_bg_pos = 0.0
v_br_bg_s = 0.0
v_br_mix = 0.0
v_br_mix_s = 0.0
v_br_on = 0.0
v_br_saved_start = 0.0
v_br_saved_width = 0.0
v_br_suppress_an = 0.0
v_buf_len = 0.0
v_buf_part1_l = 0.0
v_buf_part1_r = 0.0
v_buf_part2_l = 0.0
v_buf_part2_r = 0.0
v_buf_part3_l = 0.0
v_buf_part3_r = 0.0
v_c_factor = 0.0
v_can_sync = 0.0
v_cand_k = 0.0
v_cand_max = 0.0
v_cand_n = 0.0
v_cand_ok = 0.0
v_cand_p = 0.0
v_cand_s = 0.0
v_cand_v = 0.0
v_cl_a = 0.0
v_cl_act = 0.0
v_cl_atk = 0.0
v_cl_base = 0.0
v_cl_bl = 0.0
v_cl_br = 0.0
v_cl_c = 0.0
v_cl_center = 0.0
v_cl_dec = 0.0
v_cl_dl = 0.0
v_cl_dr = 0.0
v_cl_fr = 0.0
v_cl_g = 0.0
v_cl_i0 = 0.0
v_cl_i1 = 0.0
v_cl_i2 = 0.0
v_cl_i3 = 0.0
v_cl_l = 0.0
v_cl_latt = 0.0
v_cl_lc = 0.0
v_cl_ld = 0.0
v_cl_lg = 0.0
v_cl_lh = 0.0
v_cl_li = 0.0
v_cl_lk = 0.0
v_cl_lpk = 0.0
v_cl_lrel = 0.0
v_cl_lt = 0.0
v_cl_lth = 0.0
v_cl_m = 0.0
v_cl_max = 0.0
v_cl_mean = 0.0
v_cl_mem = 0.0
v_cl_n = 0.0
v_cl_on_prev = 0.0
v_cl_out_l = 0.0
v_cl_out_r = 0.0
v_cl_p = 0.0
v_cl_ph = 0.0
v_cl_r = 0.0
v_cl_snap = 0.0
v_cl_spr = 0.0
v_cl_stride = 0.0
v_cl_timer = 0.0
v_cl_w = 0.0
v_cl_wl = 0.0
v_cl_ws = 0.0
v_cl_wsum = 0.0
v_cl_x = 0.0
v_clk_cyc = 0.0
v_clk_cyc1 = 0.0
v_clk_cyc2 = 0.0
v_clk_cyc3 = 0.0
v_clk_len_ref = 0.0
v_clk_src = 0.0
v_clock_abs_pos = 0.0
v_cloud_center = 0.0
v_cloud_center_draw = 0.0
v_cloud_chaos = 0.0
v_cloud_density = 0.0
v_cloud_diffuse = 0.0
v_cloud_freeze = 0.0
v_cloud_lfo_depth = 0.0
v_cloud_lfo_phase = 0.0
v_cloud_lfo_rate = 0.0
v_cloud_lfo_shape = 0.0
v_cloud_mix = 0.0
v_cloud_on = 0.0
v_cloud_pitch_spread = 0.0
v_cloud_pos_mode = 0.0
v_cloud_pos_pct = 0.0
v_cloud_size = 0.0
v_cloud_spread = 0.0
v_cloud_x = 0.0
v_clr_long_pressed = 0.0
v_clr_press_time = 0.0
v_cm_active = 0.0
v_cm_dir = 0.0
v_cm_hi = 0.0
v_cm_k = 0.0
v_cm_lo = 0.0
v_cm_mode = 0.0
v_cm_sb = 0.0
v_cmd = 0.0
v_cmd_arg = 0.0
v_cmd_lag = 0.0
v_cmx = 0.0
v_co_p = 0.0
v_co_rec = 0.0
v_curr_peak = 0.0
v_curr_samp = 0.0
v_current_slice_pitch = 0.0
v_current_step_calc = 0.0
v_d_norm = 0.0
v_degradation = 0.0
v_delay_buf_l = 0.0
v_delay_buf_r = 0.0
v_delay_idx = 0.0
v_delay_len = 0.0
v_dens_bag = 0.0
v_dens_bag_i = 0.0
v_dens_carry = 0.0
v_dens_first = 0.0
v_dens_force = 0.0
v_dens_g = 0.0
v_dens_last_occ = 0.0
v_dens_len = 0.0
v_dens_len_f = 0.0
v_dens_minlen = 0.0
v_dens_next_on = 0.0
v_dens_occ = 0.0
v_dens_on = 0.0
v_dens_prev_state = 0.0
v_dens_rt = 0.0
v_dens_seg = 0.0
v_dens_slew = 0.0
v_dens_slot = 0.0
v_dens_t = 0.0
v_dens_tgt = 0.0
v_dens_ton = 0.0
v_det_cap = 0.0
v_det_chg = 0.0
v_det_hold_ms = 0.0
v_det_rel = 0.0
v_det_strict = 0.0
v_det_thresh = 0.0
v_df_a1 = 0.0
v_df_a2 = 0.0
v_df_a3 = 0.0
v_df_a4 = 0.0
v_df_b1 = 0.0
v_df_b2 = 0.0
v_df_b3 = 0.0
v_df_b4 = 0.0
v_df_d = 0.0
v_df_dl = 0.0
v_df_dr = 0.0
v_df_fb = 0.0
v_df_fl = 0.0
v_df_fr = 0.0
v_df_k = 0.0
v_df_lp_l = 0.0
v_df_lp_r = 0.0
v_df_mem = 0.0
v_df_on = 0.0
v_df_p = 0.0
v_df_sc = 0.0
v_df_w = 0.0
v_df_xl = 0.0
v_df_xr = 0.0
v_dirty_len = 0.0
v_dist_from_end = 0.0
v_dr_b = 0.0
v_dr_base = 0.0
v_dr_blk = 0.0
v_dr_cnt = 0.0
v_dr_j = 0.0
v_dr_l = 0.0
v_dr_mode = 0.0
v_dr_ni = 0.0
v_dr_nl = 0.0
v_dr_nr = 0.0
v_dr_part = 0.0
v_dr_slen = 0.0
v_dr_spn = 0.0
v_dr_t0 = 0.0
v_dr_t1 = 0.0
v_dr_tok = 0.0
v_dry_gain = 0.0
v_dt_b1 = 0.0
v_dt_b2 = 0.0
v_dt_bs = 0.0
v_dt_cap = 0.0
v_dt_eh = 0.0
v_dt_el = 0.0
v_dt_em = 0.0
v_dt_fl = 0.0
v_dt_gh = 0.0
v_dt_gl = 0.0
v_dt_gm = 0.0
v_dt_hc = 0.0
v_dt_kb = 0.0
v_dt_kd = 0.0
v_dt_mask = 0.0
v_dt_on = 0.0
v_dt_pk = 0.0
v_dt_rg = 0.0
v_dt_rh = 0.0
v_dt_ri = 0.0
v_dt_rl = 0.0
v_dt_rm = 0.0
v_dt_th = 0.0
v_dt_tr = 0.0
v_dt_x = 0.0
v_dt_xl = 0.0
v_dt_xr = 0.0
v_dub_align_ms = 0.0
v_dub_g = 0.0
v_dub_grain_ms = 0.0
v_dub_gran = 0.0
v_dub_gran_prev = 0.0
v_dub_pan = 0.0
v_dub_pf = 0.0
v_dub_pfk = 0.0
v_dv_a = 0.0
v_dv_cs = 0.0
v_dv_f = 0.0
v_dv_hold = 0.0
v_dv_j = 0.0
v_dv_lim = 0.0
v_dv_m = 0.0
v_dv_rf = 0.0
v_dv_s = 0.0
v_dv_trk = 0.0
v_dv_trkn = 0.0
v_edit_cmd = 0.0
v_eff_end = 0.0
v_eff_len = 0.0
v_eff_start = 0.0
v_effective_pitch_ratio = 0.0
v_effective_rev = 0.0
v_env = 0.0
v_ext_noinit = 0.0
v_f_samps = 0.0
v_fade_ms = 0.0
v_fade_samps = 0.0
v_feedback = 0.0
v_flutter_mod = 0.0
v_flutter_phase = 0.0
v_force_mode_exit = 0.0
v_frac = 0.0
v_frz_center = 0.0
v_frz_copying = 0.0
v_frz_i = 0.0
v_frz_l = 0.0
v_frz_len = 0.0
v_frz_max = 0.0
v_frz_n = 0.0
v_frz_prev = 0.0
v_frz_r = 0.0
v_frz_ready = 0.0
v_g_base = 0.0
v_g_bg = 0.0
v_g_dens = 0.0
v_g_dir = 0.0
v_g_dur = 0.0
v_g_l = 0.0
v_g_main = 0.0
v_g_mono = 0.0
v_g_pan = 0.0
v_g_phase = 0.0
v_g_pitch_off = 0.0
v_g_r = 0.0
v_gfx_x = 0.0
v_gfx_y = 0.0
v_gh_l = 0.0
v_gh_r = 0.0
v_ghost_pos_pct = 0.0
v_gi = 0.0
v_gl_gain = 0.0
v_gm_bpm = 0.0
v_gm_pspread_cloud = 0.0
v_gm_pspread_slicer = 0.0
v_gm_sampler_armed = 0.0
v_gm_sampler_pmode = 0.0
v_gm_sampler_release = 0.0
v_gm_sampler_root = 0.0
v_gm_sampler_voices = 0.0
v_gmem = 0.0
v_gmem_base = 0.0
v_gq = 0.0
v_gr_gain = 0.0
v_grain_data_size = 0.0
v_grain_dur = 0.0
v_grain_fade = 0.0
v_grain_mem = 0.0
v_grain_mix = 0.0
v_grain_ms = 0.0
v_grain_pitch_mult = 0.0
v_grain_target = 0.0
v_gran_now = 0.0
v_granular_l = 0.0
v_granular_r = 0.0
v_grid_pending = 0.0
v_grid_sig = 0.0
v_grid_sub = 0.0
v_gt = 0.0
v_hist_len = 0.0
v_hist_mem_start = 0.0
v_hist_redo = 0.0
v_hist_undo = 0.0
v_history_count = 0.0
v_history_head = 0.0
v_history_tail = 0.0
v_hold_samples_left = 0.0
v_i = 0.0
v_idx_clr = 0.0
v_ih_l = 0.0
v_ih_mask = 0.0
v_ih_n = 0.0
v_ih_r = 0.0
v_ih_size = 0.0
v_in0 = 0.0
v_in1 = 0.0
v_init_done = 0.0
v_input_env = 0.0
v_input_signal_active = 0.0
v_inst_idx = 0.0
v_instance_alias = 0.0
v_instance_id = 0.0
v_io_e_lock = 0.0
v_io_w_lock = 0.0
v_is_active = 0.0
v_is_dubbing = 0.0
v_is_normal_playback = 0.0
v_is_one_shot_mode = 0.0
v_is_recording = 0.0
v_is_slave = 0.0
v_keep_w = 0.0
v_last_det_h = 0.0
v_last_det_t = 0.0
v_last_ghost_pct = 0.0
v_last_grid_sub = 0.0
v_last_hold = 0.0
v_last_link = 0.0
v_last_loop_quant = 0.0
v_last_max_sl = 0.0
v_last_mouse_cap = 0.0
v_last_mouse_y = 0.0
v_last_pitch_spread = 0.0
v_last_preset = 0.0
v_last_sens = 0.0
v_last_slicer_mode = 0.0
v_last_slicer_src = 0.0
v_last_slicer_step = 0.0
v_last_slider9 = 0.0
v_last_state_target = 0.0
v_last_steps = 0.0
v_lat_samps = 0.0
v_ld_active = 0.0
v_ld_base = 0.0
v_ld_i = 0.0
v_ld_maxn = 0.0
v_ld_n = 0.0
v_ld_part = 0.0
v_ld_qid = 0.0
v_ld_ref = 0.0
v_leave_oneshot = 0.0
v_leave_slicer = 0.0
v_leave_stop = 0.0
v_left_buf = 0.0
v_len_part1 = 0.0
v_len_part2 = 0.0
v_len_part3 = 0.0
v_length = 0.0
v_lfo_offset = 0.0
v_lfo_val = 0.0
v_link_eff = 0.0
v_link_on = 0.0
v_loop_beats = 0.0
v_loop_edit_mode = 0.0
v_loop_env_pos = 0.0
v_loop_envelope = 0.0
v_loop_pos_pct = 0.0
v_loop_quant = 0.0
v_loop_start = 0.0
v_loop_width = 0.0
v_looper_hue = 0.0
v_lp_mute = 0.0
v_lut_cos = 0.0
v_lut_size = 0.0
v_manual_id = 0.0
v_master_pos = 0.0
v_master_pos1 = 0.0
v_master_pos2 = 0.0
v_master_pos3 = 0.0
v_max_grains = 0.0
v_max_history = 0.0
v_max_inst = 0.0
v_max_len_exp = 0.0
v_max_loop_sec = 0.0
v_max_slices = 0.0
v_max_transients = 0.0
v_max_wgrains = 0.0
v_maxsl_f = 0.0
v_mclk_cyc = 0.0
v_mclk_d = 0.0
v_mclk_hb = 0.0
v_mclk_len = 0.0
v_mclk_len_prev = 0.0
v_mclk_m = 0.0
v_mclk_np = 0.0
v_mclk_on = 0.0
v_mclk_pos = 0.0
v_mclk_trk = 0.0
v_mclk_valid = 0.0
v_mem_budget = 0.0
v_min_fade_samps = 0.0
v_mix = 0.0
v_ml_cool = 0.0
v_ml_fwd_free = 0.0
v_ml_guard = 0.0
v_ml_ok = 0.0
v_ml_trig = 0.0
v_mo_m1 = 0.0
v_mo_m2 = 0.0
v_mo_m3 = 0.0
v_mo_off = 0.0
v_mo_t = 0.0
v_mouse_cap = 0.0
v_mouse_click = 0.0
v_mouse_x = 0.0
v_mouse_y = 0.0
v_ms_off = 0.0
v_mult_len = 0.0
v_mute_g = 0.0
v_need_resync = 0.0
v_new_in = 0.0
v_new_out = 0.0
v_new_w = 0.0
v_num_active_voices = 0.0
v_odf2_mem = 0.0
v_odf_a_lo = 0.0
v_odf_a_mid = 0.0
v_odf_c_hi = 0.0
v_odf_c_lo = 0.0
v_odf_c_mid = 0.0
v_odf_cnt = 0.0
v_odf_cs = 0.0
v_odf_floor = 0.0
v_odf_hop = 0.0
v_odf_ix = 0.0
v_odf_ls = 0.0
v_odf_lw = 0.0
v_odf_max_n = 0.0
v_odf_mem = 0.0
v_odf_n = 0.0
v_odf_w = 0.0
v_ofrac = 0.0
v_old_end = 0.0
v_old_pos = 0.0
v_old_pos_ptr = 0.0
v_old_s0 = 0.0
v_old_s1 = 0.0
v_old_safe_pos = 0.0
v_one_shot_playing = 0.0
v_one_shot_pp_state = 0.0
v_op0 = 0.0
v_op1 = 0.0
v_op2 = 0.0
v_op3 = 0.0
v_out0 = 0.0
v_out1 = 0.0
v_out_vol = 0.0
v_p = 0.0
v_p0 = 0.0
v_p1 = 0.0
v_p2 = 0.0
v_p3 = 0.0
v_p_ang = 0.0
v_p_len = 0.0
v_p_norm = 0.0
v_p_off = 0.0
v_pan_ol = 0.0
v_pan_or = 0.0
v_param_clear_base = 0.0
v_param_clear_i = 0.0
v_param_gmem_base = 0.0
v_param_smooth_coeff = 0.0
v_part_cloud_on = 0.0
v_part_link_on = 0.0
v_part_pingpong = 0.0
v_part_pitch = 0.0
v_part_play_mode = 0.0
v_part_rev = 0.0
v_part_sep = 0.0
v_part_sm = 0.0
v_part_sp = 0.0
v_part_speed = 0.0
v_part_sref = 0.0
v_pd_arm = 0.0
v_pd_k = 0.0
v_pd_l = 0.0
v_pd_prev_l = 0.0
v_pd_prev_r = 0.0
v_pd_r = 0.0
v_peak_in_vu = 0.0
v_peak_loop_vu = 0.0
v_peak_out_vu = 0.0
v_pending_next_state = 0.0
v_pending_part_switch = 0.0
v_ping_pong_dir = 0.0
v_pingpong_on = 0.0
v_pitch = 0.0
v_pitch_ratio = 0.0
v_play_mode = 0.0
v_play_mode_changed = 0.0
v_play_state = 0.0
v_play_this_slice = 0.0
v_pos = 0.0
v_pos_step = 0.0
v_pos_step_actual = 0.0
v_preset_cur = 0.0
v_preset_mem = 0.0
v_prev_cloud_on = 0.0
v_prev_in0 = 0.0
v_prev_in1 = 0.0
v_prev_loop_start = 0.0
v_prev_loop_width = 0.0
v_prev_normal_playback = 0.0
v_prev_pingpong_on = 0.0
v_prev_pitch_ratio_sig = 0.0
v_prev_play_mode = 0.0
v_prev_rev_on = 0.0
v_prev_sm_speed = 0.0
v_prev_state_for_sync = 0.0
v_prev_sync_key = 0.0
v_prev_xcl = 0.0
v_pslot = 0.0
v_qs_b0 = 0.0
v_qs_frac = 0.0
v_qs_hit = 0.0
v_qs_i = 0.0
v_qs_mode = 0.0
v_qs_prev = 0.0
v_qs_snap = 0.0
v_qs_unit = 0.0
v_qs_wait = 0.0
v_r_bg = 0.0
v_rand_pitch_idx = 0.0
v_rate_t = 0.0
v_rd_dl = 0.0
v_rd_f = 0.0
v_rd_frac = 0.0
v_rd_i = 0.0
v_rd_last_g = 0.0
v_rd_last_l = 0.0
v_rd_last_p = 0.0
v_rd_last_pamt = 0.0
v_rd_last_pan = 0.0
v_rd_last_r = 0.0
v_rd_last_st = 0.0
v_rd_last_we = 0.0
v_rd_last_ws = 0.0
v_rd_ph = 0.0
v_rd_prev_dur = 0.0
v_rd_prev_n = 0.0
v_rd_prev_ok = 0.0
v_rd_prev_start = 0.0
v_rd_sn = 0.0
v_rd_tmp = 0.0
v_rd_valid = 0.0
v_rd_wn = 0.0
v_read_align_ms = 0.0
v_read_idx = 0.0
v_rec_cmd = 0.0
v_rec_force_free = 0.0
v_rec_lag_pend = 0.0
v_rec_ref_id = 0.0
v_rec_ref_kind = 0.0
v_rec_ref_len = 0.0
v_rec_ref_ph = 0.0
v_rec_speed = 0.0
v_rec_start_lag = 0.0
v_rec_start_time = 0.0
v_rec_stop_lag = 0.0
v_rel_pos = 0.0
v_replace_fade = 0.0
v_replace_fade_coeff = 0.0
v_req_p = 0.0
v_req_part = 0.0
v_rev_changed = 0.0
v_rev_on = 0.0
v_right_buf = 0.0
v_rnd_factor = 0.0
v_rnd_idx = 0.0
v_rp0 = 0.0
v_rp1 = 0.0
v_rp2 = 0.0
v_rp3 = 0.0
v_rp_cnt = 0.0
v_rp_part = 0.0
v_rp_pend = 0.0
v_rp_tail_on = 0.0
v_rs_to = 0.0
v_rx_seen = 0.0
v_s0 = 0.0
v_s0_safe = 0.0
v_s1 = 0.0
v_s1_safe = 0.0
v_safe_pos = 0.0
v_sampler_pitch_mode = 0.0
v_sampler_rel_u = 0.0
v_sampler_release = 0.0
v_sampler_root = 0.0
v_sampler_root_f = 0.0
v_samples_per_step = 0.0
v_samplesblock = 0.0
v_saved_manual_id = 0.0
v_sel_k = 0.0
v_sel_n = 0.0
v_sel_s = 0.0
v_seq_mem = 0.0
v_single_buf_len = 0.0
v_sl_gate = 0.0
v_sl_hi = 0.0
v_sl_lo = 0.0
v_sl_pan_amt = 0.0
v_sl_pan_k = 0.0
v_sl_pre_t = 0.0
v_sl_rd = 0.0
v_sl_rec = 0.0
v_sl_run = 0.0
v_sl_slew = 0.0
v_slice_att = 0.0
v_slice_att_eff_ms = 0.0
v_slice_att_step = 0.0
v_slice_attack_ms = 0.0
v_slice_decay_ms = 0.0
v_slice_decay_pos = 0.0
v_slice_decay_samples = 0.0
v_slice_decay_step = 0.0
v_slice_end_dist = 0.0
v_slice_env = 0.0
v_slice_g = 0.0
v_slice_gmem_base = 0.0
v_slice_gmem_i = 0.0
v_slice_hold = 0.0
v_slice_mute_gate = 0.0
v_slice_mute_step = 0.0
v_slice_mute_target = 0.0
v_slice_pan = 0.0
v_slice_pitch_mem = 0.0
v_slice_pitch_mult = 0.0
v_slicer_current_step = 0.0
v_slicer_link = 0.0
v_slicer_mode = 0.0
v_slicer_pitch_spread = 0.0
v_slicer_preset = 0.0
v_slicer_sample_counter = 0.0
v_slicer_src = 0.0
v_slicer_steps = 0.0
v_slicer_sub = 0.0
v_slot_size = 0.0
v_slw_last = 0.0
v_slx_clk = 0.0
v_slx_dg = 0.0
v_slx_env = 0.0
v_slx_fr = 0.0
v_slx_fs = 0.0
v_slx_l = 0.0
v_slx_mix = 0.0
v_slx_mix_s = 0.0
v_slx_p0 = 0.0
v_slx_p1 = 0.0
v_slx_p2 = 0.0
v_slx_p3 = 0.0
v_slx_pos = 0.0
v_slx_prev = 0.0
v_slx_r = 0.0
v_slx_rp = 0.0
v_slx_wg = 0.0
v_sm_pitch = 0.0
v_sm_speed = 0.0
v_smooth_start = 0.0
v_smooth_width = 0.0
v_smp_age = 0.0
v_smp_alloff = 0.0
v_smp_armed = 0.0
v_smp_att = 0.0
v_smp_blk = 0.0
v_smp_choke_rel = 0.0
v_smp_ev_i = 0.0
v_smp_ev_n = 0.0
v_smp_ev_note = 0.0
v_smp_ev_off = 0.0
v_smp_ev_vel = 0.0
v_smp_evmax = 0.0
v_smp_g = 0.0
v_smp_gh = 0.0
v_smp_kmode = 0.0
v_smp_l = 0.0
v_smp_mode = 0.0
v_smp_nact = 0.0
v_smp_nv = 0.0
v_smp_prev_mode = 0.0
v_smp_quick_rel = 0.0
v_smp_r = 0.0
v_smp_rl = 0.0
v_smp_rr = 0.0
v_smp_tail = 0.0
v_smp_voice = 0.0
v_smp_vs = 0.0
v_spawn_target_pos = 0.0
v_spawn_timer = 0.0
v_speed = 0.0
v_spl0 = 0.0
v_spl1 = 0.0
v_spread_offset = 0.0
v_srate = 0.0
v_src_auto = 0.0
v_st = 0.0
v_st_band = 0.0
v_st_fft = 0.0
v_st_fmax = 0.0
v_st_lag = 0.0
v_st_n = 0.0
v_st_nb = 0.0
v_st_ring = 0.0
v_st_rp = 0.0
v_st_win = 0.0
v_state = 0.0
v_state_slider = 0.0
v_state_target = 0.0
v_state_transition_fade = 0.0
v_step_len = 0.0
v_steps_f = 0.0
v_stereo_width = 0.0
v_sw_on = 0.0
v_sw_pos = 0.0
v_sy_pbase = 0.0
v_sy_plen = 0.0
v_sync_a = 0.0
v_sync_b = 0.0
v_sync_c_l = 0.0
v_sync_c_r = 0.0
v_sync_c_w = 0.0
v_sync_dev = 0.0
v_sync_exp = 0.0
v_sync_hard_resync = 0.0
v_sync_key = 0.0
v_tape_lpf_l = 0.0
v_tape_lpf_l_b = 0.0
v_tape_lpf_l_c = 0.0
v_tape_lpf_l_d = 0.0
v_tape_lpf_r = 0.0
v_tape_lpf_r_b = 0.0
v_tape_lpf_r_c = 0.0
v_tape_lpf_r_d = 0.0
v_target_grain_ms = 0.0
v_target_gt_ms = 0.0
v_target_p = 0.0
v_target_part = 0.0
v_target_pos = 0.0
v_target_sync_len = 0.0
v_tempo = 0.0
v_total_w = 0.0
v_trans_count = 0.0
v_trans_hold_ms = 0.0
v_trans_mem = 0.0
v_trans_sens = 0.0
v_trans_str = 0.0
v_ts_num = 0.0
v_ui_ab = 0.0
v_ui_ag = 0.0
v_ui_ar = 0.0
v_ui_chg = 0.0
v_ui_ds_on = 0.0
v_ui_dv = 0.0
v_ui_dv_on = 0.0
v_ui_en = 0.0
v_ui_hov = 0.0
v_varispeed = 0.0
v_vu_rel = 0.0
v_w_idx_ex = 0.0
v_w_step_ex = 0.0
v_w_tmp_ex = 0.0
v_w_val_ex = 0.0
v_warp_force = 0.0
v_warp_grid = 0.0
v_warp_on = 0.0
v_wave_export_slots = 0.0
v_wet_gain = 0.0
v_wet_s0 = 0.0
v_wet_s1 = 0.0
v_wg_c0 = 0.0
v_wg_c1 = 0.0
v_wg_el = 0.0
v_wg_es = 0.0
v_wg_fade = 0.0
v_wg_gl = 0.0
v_wg_gr = 0.0
v_wg_hop = 0.0
v_wg_lcur = 0.0
v_wg_mem = 0.0
v_wg_p0 = 0.0
v_wg_p1 = 0.0
v_wg_prev_n = 0.0
v_wg_prev_ok = 0.0
v_wg_prev_src = 0.0
v_wg_rf = 0.0
v_wg_stride = 0.0
v_wg_timer = 0.0
v_wi_ex = 0.0
v_wk_ex = 0.0
v_wow_mod = 0.0
v_wow_phase = 0.0
v_wp_a = 0.0
v_wp_atk = 0.0
v_wp_b = 0.0
v_wp_busy = 0.0
v_wp_cb = 0.0
v_wp_ci = 0.0
v_wp_cp = 0.0
v_wp_dd = 0.0
v_wp_free = 0.0
v_wp_from = 0.0
v_wp_gn = 0.0
v_wp_hop = 0.0
v_wp_hr = 0.0
v_wp_j = 0.0
v_wp_len = 0.0
v_wp_live = 0.0
v_wp_lout = 0.0
v_wp_ls = 0.0
v_wp_lsrc = 0.0
v_wp_lw = 0.0
v_wp_max = 0.0
v_wp_mk = 0.0
v_wp_mn = 0.0
v_wp_n = 0.0
v_wp_orig = 0.0
v_wp_phase = 0.0
v_wp_pr = 0.0
v_wp_prev_on = 0.0
v_wp_pub = 0.0
v_wp_rerender = 0.0
v_wp_ri = 0.0
v_wp_rr = 0.0
v_wp_scan = 0.0
v_wp_seg = 0.0
v_wp_sig = 0.0
v_wp_sig_job = 0.0
v_wp_sig_seen = 0.0
v_wp_sig_t = 0.0
v_wp_sl = 0.0
v_wp_sr = 0.0
v_wp_srr = 0.0
v_wp_ss = 0.0
v_wp_ta = 0.0
v_wp_tb = 0.0
v_wp_tg = 0.0
v_wp_tgt = 0.0
v_wp_tl = 0.0
v_wp_trr = 0.0
v_wp_wl = 0.0
v_wp_wsl = 0.0
v_wp_xn = 0.0
v_wr_guard = 0.0
v_wr_id = 0.0
v_wr_mb = 0.0
v_wr_mo = 0.0
v_wr_off = 0.0
v_wr_v = 0.0
v_wrapped = 0.0
v_write_ptr = 0.0
v_x_event = 0.0
v_x_free = 0.0
v_x_mode = 0.0
v_x_ms = 0.0
v_x_part = 0.0
v_x_per = 0.0
v_x_ph_prev = 0.0
v_xa = 0.0
v_xarm = 0.0
v_xb = 0.0
v_xf_eqp = 0.0
v_xf_g = 0.0
v_xf_inc = 0.0
v_xf_k = 0.0
v_xf_l = 0.0
v_xf_len_jump = 0.0
v_xf_len_rs = 0.0
v_xf_len_slice = 0.0
v_xf_on = 0.0
v_xf_p = 0.0
v_xf_pamt = 0.0
v_xf_pan = 0.0
v_xf_r = 0.0
v_xf_st = 0.0
v_xf_w = 0.0
v_xf_we = 0.0
v_xf_ws = 0.0
v_xfade_coeff = 0.0
v_xfade_gain = 0.0
v_xfade_pos_active = 0.0
v_xfade_pos_count = 0.0
v_xfade_pos_len = 0.0
v_xfr = 0.0
v_xi_s = 0.0
v_xp = 0.0
v_xper = 0.0
v_xph = 0.0
v_xq0 = 0.0
v_xq1 = 0.0
v_xq2 = 0.0
v_xq3 = 0.0

def f_decay_seg(L_x, L_x0, L_m0, L_x1, L_m1):
  return (L_m0 * _pow(_div(L_m1, L_m0), _div((L_x - L_x0), (L_x1 - L_x0))))

def f_decay_pos_to_ms(L_pos):
  if _tr((1.0 if L_pos <= 0.0 else 0.0)):
    _t1 = 4.0
  else:
    if _tr((1.0 if L_pos < 25.0 else 0.0)):
      _t3 = L_pos
      _t4 = f_decay_seg(_t3, 0.0, 4.0, 25.0, 20.0)
      _t2 = _t4
    else:
      if _tr((1.0 if L_pos < 50.0 else 0.0)):
        _t6 = L_pos
        _t7 = f_decay_seg(_t6, 25.0, 20.0, 50.0, 45.0)
        _t5 = _t7
      else:
        if _tr((1.0 if L_pos < 75.0 else 0.0)):
          _t9 = L_pos
          _t10 = f_decay_seg(_t9, 50.0, 45.0, 75.0, 150.0)
          _t8 = _t10
        else:
          if _tr((1.0 if L_pos < 90.0 else 0.0)):
            _t12 = L_pos
            _t13 = f_decay_seg(_t12, 75.0, 150.0, 90.0, 300.0)
            _t11 = _t13
          else:
            if _tr((1.0 if L_pos < 99.0 else 0.0)):
              _t15 = L_pos
              _t16 = f_decay_seg(_t15, 90.0, 300.0, 99.0, 500.0)
              _t14 = _t16
            else:
              if _tr((1.0 if L_pos < 100.0 else 0.0)):
                _t18 = L_pos
                _t19 = f_decay_seg(_t18, 99.0, 500.0, 100.0, 2000.0)
                _t17 = _t19
              else:
                _t17 = 2000.0
              _t14 = _t17
            _t11 = _t14
          _t8 = _t11
        _t5 = _t8
      _t2 = _t5
    _t1 = _t2
  return _t1

def f_decay_iseg(L_ms, L_x0, L_m0, L_x1, L_m1):
  _t26 = L_x0
  _t22 = (L_x1 - L_x0)
  _t20 = _div(L_ms, L_m0)
  _t21 = _log(_t20)
  _t25 = (_t22 * _t21)
  _t23 = _div(L_m1, L_m0)
  _t24 = _log(_t23)
  return (_t26 + _div(_t25, _t24))

def f_decay_ms_to_pos(L_ms):
  if _tr((1.0 if L_ms > 1950.0 else 0.0)):
    _t27 = 100.0
  else:
    if _tr((1.0 if L_ms <= 4.0 else 0.0)):
      _t28 = 0.0
    else:
      if _tr((1.0 if L_ms < 20.0 else 0.0)):
        _t30 = L_ms
        _t31 = f_decay_iseg(_t30, 0.0, 4.0, 25.0, 20.0)
        _t29 = _t31
      else:
        if _tr((1.0 if L_ms < 45.0 else 0.0)):
          _t33 = L_ms
          _t34 = f_decay_iseg(_t33, 25.0, 20.0, 50.0, 45.0)
          _t32 = _t34
        else:
          if _tr((1.0 if L_ms < 150.0 else 0.0)):
            _t36 = L_ms
            _t37 = f_decay_iseg(_t36, 50.0, 45.0, 75.0, 150.0)
            _t35 = _t37
          else:
            if _tr((1.0 if L_ms < 300.0 else 0.0)):
              _t39 = L_ms
              _t40 = f_decay_iseg(_t39, 75.0, 150.0, 90.0, 300.0)
              _t38 = _t40
            else:
              if _tr((1.0 if L_ms < 500.0 else 0.0)):
                _t42 = L_ms
                _t43 = f_decay_iseg(_t42, 90.0, 300.0, 99.0, 500.0)
                _t41 = _t43
              else:
                _t44 = L_ms
                _t45 = f_decay_iseg(_t44, 99.0, 500.0, 100.0, 2000.0)
                _t41 = _t45
              _t38 = _t41
            _t35 = _t38
          _t32 = _t35
        _t29 = _t32
      _t28 = _t29
    _t27 = _t28
  return _t27

def f_fast_tanh(L_x):
  L_x2 = 0.0
  L_x3 = 0.0
  L_x5 = 0.0
  _t46 = L_x
  _t47 = abs(_t46)
  if _tr((1.0 if _t47 > 3.0 else 0.0)):
    if _tr((1.0 if L_x > 0.0 else 0.0)):
      _t49 = 1.0
    else:
      _t49 = (-1.0)
    _t48 = _t49
  else:
    L_x2 = (L_x * L_x)
    L_x3 = (L_x2 * L_x)
    L_x5 = (L_x3 * L_x2)
    _t48 = _div((L_x * (27.0 + L_x2)), (27.0 + (9.0 * L_x2)))
  return _t48

def f_host_measure_len():
  global v_srate, v_tempo, v_ts_num
  L_t = 0.0
  L_n = 0.0
  _t50 = v_tempo
  _t51 = max(_t50, 20.0)
  L_t = _t51
  if _tr((1.0 if v_ts_num > 0.0 else 0.0)):
    _t52 = v_ts_num
  else:
    _t52 = 4.0
  L_n = _t52
  return ((v_srate * _div(60.0, L_t)) * L_n)

def f_calc_sync_len(L_current_len, L_ms_len):
  L_t = 0.0
  if _tr((1.0 if L_ms_len > 0.0 else 0.0)):
    L_t = (L_ms_len * 0.125)
    if _tr((1.0 if L_current_len <= L_t else 0.0)):
      _t54 = L_t
    else:
      L_t = (L_ms_len * 0.25)
      if _tr((1.0 if L_current_len <= L_t else 0.0)):
        _t55 = L_t
      else:
        L_t = (L_ms_len * 0.5)
        if _tr((1.0 if L_current_len <= L_t else 0.0)):
          _t56 = L_t
        else:
          _t57 = _div(L_current_len, L_ms_len)
          _t58 = _ceil(_t57)
          _t56 = (_t58 * L_ms_len)
        _t55 = _t56
      _t54 = _t55
    _t53 = _t54
  else:
    _t53 = L_current_len
  return _t53

def f_auto_nb():
  global v_ab_len, v_ab_nb, v_ab_ts, v_length, v_srate, v_ts_num
  L_nb0 = 0.0
  L_base = 0.0
  L_n = 0.0
  L_bpm = 0.0
  L_sc = 0.0
  L_bsc = 0.0
  _t59 = 1.0 if _tr((0.0 if abs(v_length - v_ab_len) < 0.00001 else 1.0)) else 0.0
  if not _t59:
    _t59 = 1.0 if _tr((0.0 if abs(v_ts_num - v_ab_ts) < 0.00001 else 1.0)) else 0.0
  if _tr(_t59):
    v_ab_len = v_length
    v_ab_ts = v_ts_num
    if _tr((1.0 if v_ts_num > 0.0 else 0.0)):
      _t61 = v_ts_num
    else:
      _t61 = 4.0
    _t62 = (_t61 + 0.5)
    _t63 = _floor(_t62)
    _t64 = _t63
    _t65 = max(1.0, _t64)
    L_nb0 = _t65
    if _tr((1.0 if abs(float(int(L_nb0) & int((L_nb0 - 1.0))) - 0.0) < 0.00001 else 0.0)):
      _t66 = 1.0
    else:
      _t66 = L_nb0
    L_base = _t66
    L_n = L_base
    L_bsc = 1000000000.0
    v_ab_nb = L_base
    for _t67 in range(max(0, int(9.0))):
      _t70 = ((60.0 * v_srate) * L_n)
      _t68 = v_length
      _t69 = max(1.0, _t68)
      L_bpm = _div(_t70, _t69)
      _t71 = _div(L_bpm, 112.0)
      _t72 = _log(_t71)
      _t73 = _t72
      _t74 = abs(_t73)
      L_sc = _t74
      if _tr((1.0 if L_sc < L_bsc else 0.0)):
        L_bsc = L_sc
        v_ab_nb = L_n
        _t75 = v_ab_nb
      else:
        _t75 = 0.0
      L_n = (L_n * 2.0)
    _t60 = 0.0
  else:
    _t60 = 0.0
  return v_ab_nb

def f_loop_beat_len():
  global v_active_part, v_gmem, v_instance_alias, v_instance_id, v_length, v_loop_beats, v_srate, v_tempo
  L_hb = 0.0
  L_nb = 0.0
  L_lk = 0.0
  L_mid = 0.0
  _t76 = v_tempo
  _t77 = max(_t76, 20.0)
  L_hb = (_div(60.0, _t77) * v_srate)
  if _tr((1.0 if v_length > 0.0 else 0.0)):
    L_lk = _gget(((v_active_part - 1.0) * 10.0))
    L_mid = _gget((((v_active_part - 1.0) * 10.0) + 1.0))
    if _tr((1.0 if v_loop_beats >= 1.0 else 0.0)):
      _t80 = (v_loop_beats + 0.5)
      _t81 = _floor(_t80)
      _t79 = _t81
    else:
      _t82 = 1.0 if _tr((1.0 if abs(L_lk - 0.0) < 0.00001 else 0.0)) else 0.0
      if not _t82:
        _t83 = 1.0 if _tr((1.0 if abs(L_lk - 1.0) < 0.00001 else 0.0)) else 0.0
        if _t83:
          _t84 = 1.0 if _tr((1.0 if abs(L_mid - v_instance_id) < 0.00001 else 0.0)) else 0.0
          if not _t84:
            _t84 = 1.0 if _tr((1.0 if abs(L_mid - v_instance_alias) < 0.00001 else 0.0)) else 0.0
          _t83 = 1.0 if _tr(_t84) else 0.0
        _t82 = 1.0 if _tr(_t83) else 0.0
      if _tr(_t82):
        _t86 = f_auto_nb()
        _t85 = _t86
      else:
        _t87 = (_div(v_length, L_hb) + 0.5)
        _t88 = _floor(_t87)
        _t89 = _t88
        _t90 = max(1.0, _t89)
        _t85 = _t90
      _t79 = _t85
    L_nb = _t79
    L_hb = _div(v_length, L_nb)
    _t78 = L_hb
  else:
    _t78 = 0.0
  return L_hb

def f_dens_next():
  global v_dens_bag, v_dens_bag_i, v_dens_carry, v_dens_last_occ, v_dens_occ, v_dens_tgt
  L_i = 0.0
  L_j = 0.0
  L_t = 0.0
  L_want = 0.0
  L_k = 0.0
  _t91 = 1.0 if _tr((1.0 if v_dens_bag_i >= 16.0 else 0.0)) else 0.0
  if not _t91:
    _t91 = 1.0 if _tr((0.0 if abs(v_dens_occ - v_dens_last_occ) < 0.00001 else 1.0)) else 0.0
  if _tr(_t91):
    if _tr((0.0 if abs(v_dens_occ - v_dens_last_occ) < 0.00001 else 1.0)):
      v_dens_carry = 0.0
      _t93 = v_dens_carry
    else:
      _t93 = 0.0
    v_dens_last_occ = v_dens_occ
    if _tr((1.0 if v_dens_occ <= 0.001 else 0.0)):
      L_k = 0.0
      v_dens_carry = 0.0
      _t94 = v_dens_carry
    else:
      L_want = ((v_dens_occ * 0.16) + v_dens_carry)
      _t95 = L_want
      _t96 = _floor(_t95)
      _t97 = _t96
      _t98 = min(16.0, _t97)
      L_k = _t98
      _t99 = (L_want - L_k)
      _t100 = min(1.0, _t99)
      v_dens_carry = _t100
      _t94 = v_dens_carry
    L_i = 0.0
    for _t101 in range(max(0, int(16.0))):
      _t102 = _ix(v_dens_bag + L_i)
      if _tr((1.0 if L_i < L_k else 0.0)):
        _t103 = 1.0
      else:
        _t103 = 0.0
      _t104 = _t103
      _mset(_t102, _t104)
      L_i = (L_i + 1.0)
    L_i = 15.0
    for _t105 in range(max(0, int(15.0))):
      _t106 = (L_i + 1.0)
      _t107 = _rand(_t106)
      _t108 = _t107
      _t109 = _floor(_t108)
      L_j = _t109
      L_t = _mget(v_dens_bag + L_i)
      _t110 = _ix(v_dens_bag + L_i)
      _t111 = _mget(v_dens_bag + L_j)
      _mset(_t110, _t111)
      _t112 = _ix(v_dens_bag + L_j)
      _t113 = L_t
      _mset(_t112, _t113)
      L_i = (L_i - 1.0)
    v_dens_bag_i = 0.0
    _t92 = v_dens_bag_i
  else:
    _t92 = 0.0
  v_dens_tgt = _mget(v_dens_bag + v_dens_bag_i)
  v_dens_bag_i = (v_dens_bag_i + 1.0)
  return v_dens_bag_i

def f_dens_pick():
  global v_dens_len, v_dens_minlen, v_dens_next_on, v_dens_occ, v_dens_seg, v_dens_t, v_dens_tgt, v_dens_ton
  L_p = 0.0
  L_l = 0.0
  L_mon = 0.0
  L_moff = 0.0
  L_err = 0.0
  L_ln = 0.0
  L_r = 0.0
  _t114 = (v_dens_occ * 0.01)
  _t115 = min(1.0, _t114)
  _t116 = _t115
  _t117 = max(0.0, _t116)
  L_p = _t117
  _t118 = v_dens_minlen
  _t119 = f_loop_beat_len()
  _t122 = (_t119 * 4.0)
  _t120 = (v_dens_len + 0.5)
  _t121 = _floor(_t120)
  _t123 = (_t122 * _pow(2.0, (-_t121)))
  _t124 = max(_t118, _t123)
  L_l = _t124
  L_mon = ((2.0 * L_l) * L_p)
  L_moff = ((2.0 * L_l) * (1.0 - L_p))
  _t125 = _rand(1.5)
  L_r = (0.25 + _t125)
  L_err = ((L_p * v_dens_t) - v_dens_ton)
  if _tr((1.0 if L_p <= 0.001 else 0.0)):
    v_dens_next_on = 0.0
    _t126 = v_dens_next_on
  else:
    _t126 = 0.0
  v_dens_tgt = v_dens_next_on
  if _tr(v_dens_tgt):
    _t127 = ((L_mon * L_r) + (0.5 * L_err))
  else:
    _t127 = ((L_moff * L_r) - (0.5 * L_err))
  L_ln = _t127
  _t128 = v_dens_minlen
  _t129 = L_ln
  _t130 = (4.0 * L_l)
  _t131 = min(_t129, _t130)
  _t132 = _t131
  _t133 = max(_t128, _t132)
  L_ln = _t133
  v_dens_seg = L_ln
  v_dens_t = (v_dens_t + L_ln)
  if _tr(v_dens_tgt):
    v_dens_ton = (v_dens_ton + L_ln)
    _t134 = v_dens_ton
  else:
    _t134 = 0.0
  if _tr((1.0 if L_p <= 0.001 else 0.0)):
    _t135 = 0.0
  else:
    _t135 = (0.0 if _tr(v_dens_tgt) else 1.0)
  v_dens_next_on = _t135
  return v_dens_next_on

def f_df_alloc(L_n):
  global v_df_p, v_df_sc
  L_b = 0.0
  L_b = v_df_p
  _t136 = (L_n * v_df_sc)
  _t137 = _ceil(_t136)
  _t138 = _t137
  _t139 = max(2.0, _t138)
  L_n = _t139
  _t140 = _ix(L_b + 0.0)
  _t141 = 0.0
  _mset(_t140, _t141)
  _t142 = _ix(L_b + 1.0)
  _t143 = L_n
  _mset(_t142, _t143)
  _t144 = (L_b + 2.0)
  _t145 = L_n
  _t146 = _memset(_t144, 0.0, _t145)
  v_df_p = (v_df_p + (L_n + 4.0))
  return L_b

def f_slicer_beats():
  global v_slicer_sub
  if _tr((1.0 if abs(v_slicer_sub - 0.0) < 0.00001 else 0.0)):
    _t147 = 1.0
  else:
    if _tr((1.0 if abs(v_slicer_sub - 1.0) < 0.00001 else 0.0)):
      _t148 = 0.5
    else:
      if _tr((1.0 if abs(v_slicer_sub - 2.0) < 0.00001 else 0.0)):
        _t149 = _div(1.0, 3.0)
      else:
        if _tr((1.0 if abs(v_slicer_sub - 3.0) < 0.00001 else 0.0)):
          _t150 = 0.25
        else:
          if _tr((1.0 if abs(v_slicer_sub - 4.0) < 0.00001 else 0.0)):
            _t151 = _div(1.0, 6.0)
          else:
            _t151 = 0.125
          _t150 = _t151
        _t149 = _t150
      _t148 = _t149
    _t147 = _t148
  return _t147

def f_grid_beats():
  global v_grid_sub
  if _tr((1.0 if abs(v_grid_sub - 0.0) < 0.00001 else 0.0)):
    _t152 = 1.0
  else:
    if _tr((1.0 if abs(v_grid_sub - 1.0) < 0.00001 else 0.0)):
      _t153 = 0.5
    else:
      if _tr((1.0 if abs(v_grid_sub - 2.0) < 0.00001 else 0.0)):
        _t154 = _div(1.0, 3.0)
      else:
        if _tr((1.0 if abs(v_grid_sub - 3.0) < 0.00001 else 0.0)):
          _t155 = 0.25
        else:
          if _tr((1.0 if abs(v_grid_sub - 4.0) < 0.00001 else 0.0)):
            _t156 = _div(1.0, 6.0)
          else:
            if _tr((1.0 if abs(v_grid_sub - 5.0) < 0.00001 else 0.0)):
              _t157 = 0.125
            else:
              if _tr((1.0 if abs(v_grid_sub - 6.0) < 0.00001 else 0.0)):
                _t158 = _div(1.0, 12.0)
              else:
                if _tr((1.0 if abs(v_grid_sub - 7.0) < 0.00001 else 0.0)):
                  _t159 = 0.0625
                else:
                  if _tr((1.0 if abs(v_grid_sub - 8.0) < 0.00001 else 0.0)):
                    _t160 = _div(1.0, 24.0)
                  else:
                    _t160 = 0.03125
                  _t159 = _t160
                _t158 = _t159
              _t157 = _t158
            _t156 = _t157
          _t155 = _t156
        _t154 = _t155
      _t153 = _t154
    _t152 = _t153
  return _t152

def f_grid_div():
  _t161 = f_grid_beats()
  _t162 = (_div(4.0, _t161) + 0.5)
  _t163 = _floor(_t162)
  _t164 = _t163
  _t165 = max(1.0, _t164)
  return _t165

def f_sl_linked():
  global v_length, v_slicer_link, v_slicer_src
  _t167 = 1.0 if _tr((1.0 if v_slicer_link >= 0.5 else 0.0)) else 0.0
  if _t167:
    _t167 = 1.0 if _tr((1.0 if abs(v_slicer_src - 1.0) < 0.00001 else 0.0)) else 0.0
  _t166 = 1.0 if _tr(_t167) else 0.0
  if _t166:
    _t166 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
  return _t166

def f_grid_pick(L_n):
  global v_grid_sub, v_loop_width, v_max_transients, v_srate
  L_s = 0.0
  L_c = 0.0
  L_bs = 0.0
  L_bd = 0.0
  L_d = 0.0
  L_bd = 1000000000.0
  L_bs = v_grid_sub
  L_s = 0.0
  for _t168 in range(max(0, int(10.0))):
    v_grid_sub = L_s
    _t169 = v_max_transients
    _t176 = v_loop_width
    _t170 = (v_srate * 0.005)
    _t171 = f_loop_beat_len()
    _t173 = _t171
    _t172 = f_grid_beats()
    _t174 = (_t173 * _t172)
    _t175 = max(_t170, _t174)
    _t177 = _div(_t176, _t175)
    _t178 = min(_t169, _t177)
    L_c = _t178
    _t179 = L_c
    _t180 = max(1.0, _t179)
    _t181 = _div(_t180, L_n)
    _t182 = _log(_t181)
    _t183 = _t182
    _t184 = abs(_t183)
    L_d = _t184
    if _tr((1.0 if L_d < L_bd else 0.0)):
      L_bd = L_d
      L_bs = L_s
      _t185 = L_bs
    else:
      _t185 = 0.0
    L_s = (L_s + 1.0)
  v_grid_sub = L_bs
  return v_grid_sub

def f_grid_signature():
  global v_grid_sub, v_length, v_loop_beats, v_loop_start, v_loop_width, v_slicer_link
  _t187 = ((v_length + (v_loop_start * 3.0)) + (v_loop_width * 7.0))
  _t186 = f_loop_beat_len()
  _t189 = (((_t187 + (_t186 * 13.0)) + (v_grid_sub * 101.0)) + (v_loop_beats * 1009.0))
  if _tr((1.0 if v_slicer_link >= 0.5 else 0.0)):
    _t188 = 10007.0
  else:
    _t188 = 0.0
  return (_t189 + _t188)

def f_grid_build():
  global v_analysing, v_grid_pending, v_grid_sig, v_loop_start, v_loop_width, v_max_transients, v_srate, v_trans_count, v_trans_mem
  L_st = 0.0
  L_e = 0.0
  _t190 = (v_srate * 0.005)
  _t191 = f_loop_beat_len()
  _t193 = _t191
  _t192 = f_grid_beats()
  _t194 = (_t193 * _t192)
  _t195 = max(_t190, _t194)
  L_st = _t195
  L_e = ((v_loop_start + v_loop_width) - 1.0)
  v_trans_count = 0.0
  _t196 = 0
  while True:
    _t197 = 1.0 if _tr((1.0 if v_trans_count < v_max_transients else 0.0)) else 0.0
    if _t197:
      _t197 = 1.0 if _tr((1.0 if (v_loop_start + (v_trans_count * L_st)) < L_e else 0.0)) else 0.0
    if not _tr(_t197): break
    _t198 = _ix(v_trans_mem + v_trans_count)
    _t199 = (v_loop_start + (v_trans_count * L_st))
    _mset(_t198, _t199)
    v_trans_count = (v_trans_count + 1.0)
    _t196 += 1
    if _t196 > 1000000: break
  v_analysing = 0.0
  v_grid_pending = 1.0
  _t200 = f_grid_signature()
  v_grid_sig = _t200
  return v_grid_sig

def f_odf_refine(L_p):
  global v_left_buf, v_length, v_loop_start, v_odf_hop, v_right_buf, v_srate
  L_a = 0.0
  L_pk = 0.0
  L_j = 0.0
  L_k = 0.0
  L_q = 0.0
  L_z = 0.0
  _t201 = v_loop_start
  _t202 = L_p
  _t203 = max(_t201, _t202)
  _t204 = _t203
  _t205 = _floor(_t204)
  L_p = _t205
  L_pk = 0.0
  L_j = 0.0
  for _t206 in range(max(0, int((v_odf_hop * 4.0)))):
    L_k = (L_p + L_j)
    if _tr((1.0 if L_k < v_length else 0.0)):
      _t208 = _mget(v_left_buf + L_k)
      _t209 = abs(_t208)
      _t212 = _t209
      _t210 = _mget(v_right_buf + L_k)
      _t211 = abs(_t210)
      L_a = (_t212 + _t211)
      if _tr((1.0 if L_a > L_pk else 0.0)):
        L_pk = L_a
        _t213 = L_pk
      else:
        _t213 = 0.0
      _t207 = _t213
    else:
      _t207 = 0.0
    L_j = (L_j + 1.0)
  L_a = 0.0
  L_j = 1.0
  _t214 = 0
  while True:
    _t215 = 1.0 if _tr((1.0 if L_j <= v_odf_hop else 0.0)) else 0.0
    if _t215:
      _t218 = (L_p - L_j)
      _t216 = v_loop_start
      _t217 = _floor(_t216)
      _t215 = 1.0 if _tr((1.0 if _t218 >= _t217 else 0.0)) else 0.0
    if not _tr(_t215): break
    _t219 = L_a
    _t220 = _mget(v_left_buf + (L_p - L_j))
    _t221 = abs(_t220)
    _t224 = _t221
    _t222 = _mget(v_right_buf + (L_p - L_j))
    _t223 = abs(_t222)
    _t225 = (_t224 + _t223)
    _t226 = max(_t219, _t225)
    L_a = _t226
    L_j = (L_j + 1.0)
    _t214 += 1
    if _t214 > 1000000: break
  if _tr((1.0 if L_pk > (L_a * 2.0) else 0.0)):
    _t227 = (L_a + (0.25 * (L_pk - L_a)))
  else:
    _t227 = (L_pk * 0.15)
  L_a = _t227
  _t228 = L_a
  _t229 = (L_pk * 0.15)
  _t230 = max(_t228, _t229)
  L_a = _t230
  L_q = (-1.0)
  L_j = 0.0
  _t231 = 0
  while True:
    _t232 = 1.0 if _tr((1.0 if L_q < 0.0 else 0.0)) else 0.0
    if _t232:
      _t232 = 1.0 if _tr((1.0 if L_j < (v_odf_hop * 3.0) else 0.0)) else 0.0
    if not _tr(_t232): break
    L_k = (L_p + L_j)
    _t233 = 1.0 if _tr((1.0 if L_k < v_length else 0.0)) else 0.0
    if _t233:
      _t234 = _mget(v_left_buf + L_k)
      _t235 = abs(_t234)
      _t238 = _t235
      _t236 = _mget(v_right_buf + L_k)
      _t237 = abs(_t236)
      _t233 = 1.0 if _tr((1.0 if (_t238 + _t237) > L_a else 0.0)) else 0.0
    if _tr(_t233):
      L_q = L_k
      _t239 = L_q
    else:
      _t239 = 0.0
    L_j = (L_j + 1.0)
    _t231 += 1
    if _t231 > 1000000: break
  if _tr((1.0 if L_q < 0.0 else 0.0)):
    L_q = L_p
    _t240 = L_q
  else:
    _t240 = 0.0
  _t241 = v_loop_start
  _t242 = _floor(_t241)
  _t243 = (_t242 + 2.0)
  _t246 = L_q
  _t244 = (v_srate * 0.0005)
  _t245 = _floor(_t244)
  _t247 = (_t246 - _t245)
  _t248 = max(_t243, _t247)
  L_q = _t248
  L_z = L_q
  L_j = 0.0
  _t249 = 0
  while True:
    _t253 = L_j
    _t251 = (v_srate * 0.001)
    _t252 = _floor(_t251)
    _t250 = 1.0 if _tr((1.0 if _t253 < _t252 else 0.0)) else 0.0
    if _t250:
      _t256 = (L_q - L_j)
      _t254 = v_loop_start
      _t255 = _floor(_t254)
      _t250 = 1.0 if _tr((1.0 if _t256 > (_t255 + 1.0) else 0.0)) else 0.0
    if not _tr(_t250): break
    if _tr((1.0 if ((_mget(v_left_buf + (L_q - L_j)) + _mget(v_right_buf + (L_q - L_j))) * (_mget(v_left_buf + ((L_q - L_j) - 1.0)) + _mget(v_right_buf + ((L_q - L_j) - 1.0)))) <= 0.0 else 0.0)):
      L_z = (L_q - L_j)
      L_j = 100000.0
      _t257 = L_j
    else:
      L_j = (L_j + 1.0)
      _t257 = L_j
    _t249 += 1
    if _t249 > 1000000: break
  return L_z

def f_dt_emit():
  global v_cand_k, v_cand_max, v_cand_n, v_cand_ok, v_cand_s, v_cand_v, v_dt_bs, v_dt_cap, v_dt_mask, v_dt_on, v_dt_pk
  L_j = 0.0
  L_j = (v_cand_n - 1.0)
  _t258 = 1.0 if _tr((1.0 if v_cand_n > 0.0 else 0.0)) else 0.0
  if _t258:
    _t258 = 1.0 if _tr((1.0 if (v_dt_on - _mget(v_cand_k + L_j)) < v_dt_mask else 0.0)) else 0.0
  if _tr(_t258):
    if _tr((1.0 if v_dt_pk > _mget(v_cand_s + L_j) else 0.0)):
      _t261 = _ix(v_cand_k + L_j)
      _t262 = v_dt_on
      _mset(_t261, _t262)
      _t263 = _ix(v_cand_s + L_j)
      _t264 = v_dt_pk
      _mset(_t263, _t264)
      _t265 = _ix(v_cand_v + L_j)
      _t266 = v_dt_bs
      _t267 = v_dt_cap
      _t268 = min(_t266, _t267)
      _t269 = _t268
      _mset(_t265, _t269)
      _t260 = _t269
    else:
      _t260 = 0.0
    _t259 = _t260
  else:
    if _tr((1.0 if v_cand_n < v_cand_max else 0.0)):
      _t271 = _ix(v_cand_k + v_cand_n)
      _t272 = v_dt_on
      _mset(_t271, _t272)
      _t273 = _ix(v_cand_s + v_cand_n)
      _t274 = v_dt_pk
      _mset(_t273, _t274)
      _t275 = _ix(v_cand_v + v_cand_n)
      _t276 = v_dt_bs
      _t277 = v_dt_cap
      _t278 = min(_t276, _t277)
      _t279 = _t278
      _mset(_t275, _t279)
      _t280 = _ix(v_cand_ok + v_cand_n)
      _t281 = 1.0
      _mset(_t280, _t281)
      v_cand_n = (v_cand_n + 1.0)
      _t270 = v_cand_n
    else:
      _t270 = 0.0
    _t259 = _t270
  return _t259

def f_dt_con(L_e, L_g, L_k):
  global v_dt_fl, v_dt_rg, v_dt_ri
  L_o = 0.0
  L_o = _mget(v_dt_rg + ((L_k * 8.0) + v_dt_ri))
  _t282 = _ix(v_dt_rg + ((L_k * 8.0) + v_dt_ri))
  _t283 = L_e
  _mset(_t282, _t283)
  _t287 = (L_e + v_dt_fl)
  _t284 = L_g
  _t285 = L_o
  _t286 = max(_t284, _t285)
  _t288 = _div(_t287, (_t286 + v_dt_fl))
  _t289 = _log10(_t288)
  _t290 = (20.0 * _t289)
  _t291 = max(0.0, _t290)
  return _t291

def f_dt_hop():
  global v_ana_k, v_det_hold_ms, v_det_thresh, v_dt_bs, v_dt_eh, v_dt_el, v_dt_em, v_dt_fl, v_dt_gh, v_dt_gl, v_dt_gm, v_dt_kb, v_dt_kd, v_dt_on, v_dt_pk, v_dt_rg, v_dt_ri, v_dt_th, v_dt_tr, v_dv_a, v_dv_f, v_dv_hold, v_odf_hop, v_odf_ls, v_srate
  L_cl = 0.0
  L_cm = 0.0
  L_ch = 0.0
  L_mx = 0.0
  L_sc = 0.0
  L_j = 0.0
  _t292 = (v_det_thresh * 0.5)
  _t293 = max(0.0005, _t292)
  v_dt_fl = _t293
  if _tr((1.0 if v_dt_gl < 0.0 else 0.0)):
    v_dt_gl = v_dt_el
    v_dt_gm = v_dt_em
    v_dt_gh = v_dt_eh
    L_j = 0.0
    for _t295 in range(max(0, int(8.0))):
      _t296 = _ix(v_dt_rg + L_j)
      _t297 = v_dt_el
      _mset(_t296, _t297)
      _t298 = _ix(v_dt_rg + (8.0 + L_j))
      _t299 = v_dt_em
      _mset(_t298, _t299)
      _t300 = _ix(v_dt_rg + (16.0 + L_j))
      _t301 = v_dt_eh
      _mset(_t300, _t301)
      L_j = (L_j + 1.0)
    _t294 = 0.0
  else:
    _t294 = 0.0
  _t302 = v_dt_el
  _t303 = v_dt_gl
  _t304 = f_dt_con(_t302, _t303, 0.0)
  L_cl = _t304
  _t305 = v_dt_em
  _t306 = v_dt_gm
  _t307 = f_dt_con(_t305, _t306, 1.0)
  L_cm = _t307
  _t308 = v_dt_eh
  _t309 = v_dt_gh
  _t310 = f_dt_con(_t308, _t309, 2.0)
  L_ch = _t310
  v_dt_ri = _mod((v_dt_ri + 1.0), 8.0)
  _t311 = L_cl
  _t312 = L_cm
  _t313 = L_ch
  _t314 = max(_t312, _t313)
  _t315 = _t314
  _t316 = max(_t311, _t315)
  L_mx = _t316
  L_sc = (L_mx + (0.5 * (((L_cl + L_cm) + L_ch) - L_mx)))
  if _tr((1.0 if v_dt_tr > 0.0 else 0.0)):
    if _tr((1.0 if L_sc > v_dt_bs else 0.0)):
      v_dt_bs = L_sc
      _t318 = v_dt_bs
    else:
      _t318 = 0.0
    v_dt_tr = (v_dt_tr - 1.0)
    if _tr((1.0 if v_dt_tr <= 0.0 else 0.0)):
      _t320 = f_dt_emit()
      _t319 = _t320
    else:
      _t319 = 0.0
    _t317 = _t319
  else:
    _t323 = 1.0 if _tr((1.0 if v_ana_k >= v_odf_ls else 0.0)) else 0.0
    if _t323:
      _t323 = 1.0 if _tr((1.0 if v_dv_hold <= 0.0 else 0.0)) else 0.0
    _t322 = 1.0 if _tr(_t323) else 0.0
    if _t322:
      _t322 = 1.0 if _tr((1.0 if L_sc >= v_dt_th else 0.0)) else 0.0
    _t321 = 1.0 if _tr(_t322) else 0.0
    if _t321:
      _t321 = 1.0 if _tr((1.0 if v_dv_f >= v_det_thresh else 0.0)) else 0.0
    if _tr(_t321):
      v_dt_tr = 4.0
      v_dt_bs = L_sc
      _t325 = v_odf_ls
      _t326 = (v_ana_k - v_odf_hop)
      _t327 = max(_t325, _t326)
      v_dt_on = _t327
      v_dt_pk = v_dv_a
      v_dv_hold = ((v_srate * v_det_hold_ms) * 0.001)
      _t324 = v_dv_hold
    else:
      _t324 = 0.0
    _t317 = _t324
  if _tr((1.0 if v_dt_el > v_dt_gl else 0.0)):
    _t328 = v_dt_kb
  else:
    _t328 = v_dt_kd
  v_dt_gl = (v_dt_gl + (_t328 * (v_dt_el - v_dt_gl)))
  if _tr((1.0 if v_dt_em > v_dt_gm else 0.0)):
    _t329 = v_dt_kb
  else:
    _t329 = v_dt_kd
  v_dt_gm = (v_dt_gm + (_t329 * (v_dt_em - v_dt_gm)))
  if _tr((1.0 if v_dt_eh > v_dt_gh else 0.0)):
    _t330 = v_dt_kb
  else:
    _t330 = v_dt_kd
  v_dt_gh = (v_dt_gh + (_t330 * (v_dt_eh - v_dt_gh)))
  return v_dt_gh

def f_start_analysis_ex(L_keep):
  global v_an_after_wp, v_an_keep, v_ana_end, v_ana_k, v_ana_max_peak, v_analysing, v_cand_n, v_dt_b1, v_dt_b2, v_dt_eh, v_dt_el, v_dt_em, v_dt_gl, v_dt_hc, v_dt_pk, v_dt_tr, v_dv_f, v_dv_hold, v_dv_s, v_dv_trk, v_length, v_loop_start, v_loop_width, v_odf_hop, v_slicer_src, v_src_auto, v_trans_count, v_wp_scan
  L_j = 0.0
  if _tr(v_wp_scan):
    v_an_after_wp = 1.0
    _t331 = v_an_after_wp
  else:
    if _tr((1.0 if v_length > 0.0 else 0.0)):
      _t333 = 1.0 if _tr((1.0 if abs(v_slicer_src - 1.0) < 0.00001 else 0.0)) else 0.0
      if _t333:
        _t333 = 1.0 if _tr((0.0 if _tr(v_src_auto) else 1.0)) else 0.0
      if _tr(_t333):
        _t335 = f_grid_build()
        _t334 = _t335
      else:
        if _tr((0.0 if _tr(L_keep) else 1.0)):
          v_trans_count = 0.0
          _t336 = v_trans_count
        else:
          _t336 = 0.0
        v_an_keep = L_keep
        _t337 = v_loop_start
        _t338 = _floor(_t337)
        v_ana_k = (_t338 - (v_odf_hop * 40.0))
        _t339 = (v_loop_start + v_loop_width)
        _t340 = _floor(_t339)
        v_ana_end = _t340
        v_cand_n = 0.0
        v_dv_f = 0.0
        v_dv_s = 0.0
        v_dv_hold = 0.0
        v_dv_trk = 0.0
        v_ana_max_peak = 0.0001
        v_dt_b1 = 0.0
        v_dt_b2 = 0.0
        v_dt_el = 0.0
        v_dt_em = 0.0
        v_dt_eh = 0.0
        v_dt_gl = (-1.0)
        v_dt_hc = 0.0
        v_dt_tr = 0.0
        v_dt_pk = 0.0
        v_analysing = 1.0
        _t334 = v_analysing
      _t332 = _t334
    else:
      _t332 = 0.0
    _t331 = _t332
  return _t331

def f_start_analysis():
  _t341 = f_start_analysis_ex(0.0)
  return _t341

def f_switch_history_slot(L_idx):
  global v_active_history_idx, v_active_part, v_buf_part1_l, v_buf_part1_r, v_buf_part2_l, v_buf_part2_r, v_buf_part3_l, v_buf_part3_r, v_hist_mem_start, v_left_buf, v_right_buf, v_single_buf_len, v_slot_size
  v_active_history_idx = L_idx
  if _tr((1.0 if abs(L_idx - 0.0) < 0.00001 else 0.0)):
    if _tr((1.0 if abs(v_active_part - 1.0) < 0.00001 else 0.0)):
      _t343 = v_buf_part1_l
    else:
      if _tr((1.0 if abs(v_active_part - 2.0) < 0.00001 else 0.0)):
        _t344 = v_buf_part2_l
      else:
        _t344 = v_buf_part3_l
      _t343 = _t344
    v_left_buf = _t343
    if _tr((1.0 if abs(v_active_part - 1.0) < 0.00001 else 0.0)):
      _t345 = v_buf_part1_r
    else:
      if _tr((1.0 if abs(v_active_part - 2.0) < 0.00001 else 0.0)):
        _t346 = v_buf_part2_r
      else:
        _t346 = v_buf_part3_r
      _t345 = _t346
    v_right_buf = _t345
    _t342 = v_right_buf
  else:
    v_left_buf = (v_hist_mem_start + ((L_idx - 1.0) * v_slot_size))
    v_right_buf = (v_left_buf + v_single_buf_len)
    _t342 = v_right_buf
  return _t342

def f_transparent_soft_clip(L_x):
  L_ax = 0.0
  L_excess = 0.0
  _t347 = L_x
  _t348 = abs(_t347)
  L_ax = _t348
  if _tr((1.0 if L_ax > 0.95 else 0.0)):
    L_excess = (L_ax - 0.95)
    if _tr((1.0 if L_x > 0.0 else 0.0)):
      _t350 = 1.0
    else:
      _t350 = (-1.0)
    _t349 = (_t350 * (0.95 + (0.05 * _div(L_excess, (0.05 + L_excess)))))
  else:
    _t349 = L_x
  return _t349

def f_wg_splat(L_a, L_b, L_env, L_sb):
  global v_acc_hi, v_acc_len, v_acc_lo, v_buf_len, v_length, v_stereo_width, v_wg_c0, v_wg_c1, v_wg_el, v_wg_es, v_wg_gl, v_wg_gr, v_wg_p0, v_wg_p1, v_wg_rf
  L_lo = 0.0
  L_hi = 0.0
  L_span = 0.0
  L_k = 0.0
  L_k_end = 0.0
  L_steps = 0.0
  L_seg_a = 0.0
  L_seg_b = 0.0
  L_wgt = 0.0
  L_tn = 0.0
  L_vl = 0.0
  L_vr = 0.0
  L_kk = 0.0
  L_w_ = 0.0
  L_mono = 0.0
  L_yr_b = 0.0
  L_w_b = 0.0
  _t351 = L_a
  _t352 = L_b
  _t353 = min(_t351, _t352)
  L_lo = _t353
  _t354 = L_a
  _t355 = L_b
  _t356 = max(_t354, _t355)
  L_hi = _t356
  _t357 = (L_hi - L_lo)
  _t358 = max(_t357, 0.0001)
  L_span = _t358
  _t359 = L_lo
  _t360 = _floor(_t359)
  L_k = _t360
  _t361 = L_hi
  _t362 = _floor(_t361)
  L_k_end = _t362
  _t363 = ((L_k_end - L_k) + 1.0)
  _t364 = min(_t363, 24.0)
  L_steps = _t364
  L_yr_b = (L_sb + v_acc_len)
  L_w_b = (L_sb + (v_acc_len * 2.0))
  for _t365 in range(max(0, int(L_steps))):
    _t366 = L_lo
    _t367 = L_k
    _t368 = max(_t366, _t367)
    L_seg_a = _t368
    _t369 = L_hi
    _t370 = (L_k + 1.0)
    _t371 = min(_t369, _t370)
    L_seg_b = _t371
    L_wgt = (L_seg_b - L_seg_a)
    if _tr((1.0 if L_wgt > 0.0 else 0.0)):
      L_tn = _div((((L_seg_a + L_seg_b) * 0.5) - L_lo), L_span)
      if _tr((1.0 if L_a > L_b else 0.0)):
        L_tn = (1.0 - L_tn)
        _t373 = L_tn
      else:
        _t373 = 0.0
      L_vl = (v_wg_p0 + ((v_wg_c0 - v_wg_p0) * L_tn))
      L_vr = (v_wg_p1 + ((v_wg_c1 - v_wg_p1) * L_tn))
      if _tr((1.0 if v_stereo_width > 0.0001 else 0.0)):
        L_mono = ((L_vl + L_vr) * 0.5)
        L_vl = (L_mono * v_wg_gl)
        L_vr = (L_mono * v_wg_gr)
        _t374 = L_vr
      else:
        _t374 = 0.0
      L_kk = (L_k - v_wg_es)
      _t375 = _div(L_kk, v_wg_el)
      _t376 = _floor(_t375)
      L_kk = (L_kk - (_t376 * v_wg_el))
      L_kk = (L_kk + v_wg_es)
      _t377 = 1.0 if _tr((1.0 if L_kk >= 0.0 else 0.0)) else 0.0
      if _t377:
        _t379 = L_kk
        if _tr((1.0 if v_length > 0.0 else 0.0)):
          _t378 = v_length
        else:
          _t378 = v_buf_len
        _t377 = 1.0 if _tr((1.0 if _t379 < _t378 else 0.0)) else 0.0
      if _tr(_t377):
        L_w_ = ((L_env * L_wgt) * v_wg_rf)
        _t381 = _ix(L_sb + L_kk)
        _t382 = (_mget(_t381) + (L_vl * L_w_))
        _mset(_t381, _t382)
        _t383 = _ix(L_yr_b + L_kk)
        _t384 = (_mget(_t383) + (L_vr * L_w_))
        _mset(_t383, _t384)
        _t385 = _ix(L_w_b + L_kk)
        _t386 = (_mget(_t385) + L_w_)
        _mset(_t385, _t386)
        if _tr((1.0 if L_kk < v_acc_lo else 0.0)):
          v_acc_lo = L_kk
          _t387 = v_acc_lo
        else:
          _t387 = 0.0
        if _tr((1.0 if L_kk > v_acc_hi else 0.0)):
          v_acc_hi = L_kk
          _t388 = v_acc_hi
        else:
          _t388 = 0.0
        _t380 = _t388
      else:
        _t380 = 0.0
      _t372 = _t380
    else:
      _t372 = 0.0
    L_k = (L_k + 1.0)
  return 0.0

def f_wg_pick(L_s_nom, L_t0, L_sn, L_wn):
  global v_ih_l, v_ih_mask, v_ih_r
  L_best = 0.0
  L_bestd = 0.0
  L_dd = 0.0
  L_k = 0.0
  L_c = 0.0
  L_num = 0.0
  L_en = 0.0
  L_sc = 0.0
  L_stp = 0.0
  if _tr((1.0 if (L_sn * L_wn) > 40000.0 else 0.0)):
    _t389 = 2.0
  else:
    _t389 = 1.0
  L_stp = _t389
  L_best = (-1000000000.0)
  L_bestd = 0.0
  L_dd = (-L_sn)
  _t390 = 0
  while True:
    if not _tr((1.0 if L_dd <= L_sn else 0.0)): break
    L_num = 0.0
    L_en = 1e-09
    L_k = 0.0
    _t391 = 0
    while True:
      if not _tr((1.0 if L_k < L_wn else 0.0)): break
      L_c = (_mget(v_ih_l + float(int(((L_s_nom + L_dd) + L_k)) & int(v_ih_mask))) + _mget(v_ih_r + float(int(((L_s_nom + L_dd) + L_k)) & int(v_ih_mask))))
      L_num = (L_num + (L_c * (_mget(v_ih_l + float(int((L_t0 + L_k)) & int(v_ih_mask))) + _mget(v_ih_r + float(int((L_t0 + L_k)) & int(v_ih_mask))))))
      L_en = (L_en + (L_c * L_c))
      L_k = (L_k + L_stp)
      _t391 += 1
      if _t391 > 1000000: break
    _t394 = L_num
    _t392 = L_en
    _t393 = _sqrt(_t392)
    L_sc = _div(_t394, _t393)
    if _tr((1.0 if L_sc > L_best else 0.0)):
      L_best = L_sc
      L_bestd = L_dd
      _t395 = L_bestd
    else:
      _t395 = 0.0
    L_dd = (L_dd + L_stp)
    _t390 += 1
    if _t390 > 1000000: break
  return L_bestd

def f_ih_wrap():
  global v_ih_n, v_max_wgrains, v_wg_mem, v_wg_prev_n, v_wg_prev_src, v_wg_stride
  L_gi = 0.0
  L_gb = 0.0
  v_ih_n = (v_ih_n - 1073741824.0)
  v_wg_prev_src = (v_wg_prev_src - 1073741824.0)
  v_wg_prev_n = (v_wg_prev_n - 1073741824.0)
  L_gi = 0.0
  for _t396 in range(max(0, int(v_max_wgrains))):
    L_gb = (v_wg_mem + (L_gi * v_wg_stride))
    _t397 = _ix(L_gb + 3.0)
    _t398 = (_mget(_t397) - 1073741824.0)
    _mset(_t397, _t398)
    L_gi = (L_gi + 1.0)
  return 0.0

def f_rd_tp(L_x):
  global v_eff_end, v_eff_start, v_left_buf, v_right_buf
  L_k = 0.0
  _t399 = L_x
  _t400 = _floor(_t399)
  L_k = _t400
  _t403 = L_k
  _t401 = v_eff_start
  _t402 = _floor(_t401)
  _t411 = (_t403 - _t402)
  _t404 = v_eff_end
  _t405 = _floor(_t404)
  _t408 = _t405
  _t406 = v_eff_start
  _t407 = _floor(_t406)
  _t409 = (_t408 - _t407)
  _t410 = max(_t409, 1.0)
  _t412 = _div(_t411, _t410)
  _t413 = _floor(_t412)
  _t421 = _t413
  _t414 = v_eff_end
  _t415 = _floor(_t414)
  _t418 = _t415
  _t416 = v_eff_start
  _t417 = _floor(_t416)
  _t419 = (_t418 - _t417)
  _t420 = max(_t419, 1.0)
  L_k = (L_k - (_t421 * _t420))
  _t422 = v_eff_start
  _t423 = _floor(_t422)
  _t424 = _t423
  _t425 = v_eff_end
  _t426 = _floor(_t425)
  _t427 = (_t426 - 1.0)
  _t428 = L_k
  _t429 = min(_t427, _t428)
  _t430 = _t429
  _t431 = max(_t424, _t430)
  L_k = _t431
  return (_mget(v_left_buf + L_k) + _mget(v_right_buf + L_k))

def f_rd_score(L_p, L_stp, L_n):
  global v_rd_tmp
  L_i = 0.0
  L_num = 0.0
  L_en = 0.0
  L_c = 0.0
  L_num = 0.0
  L_en = 1e-09
  L_i = 0.0
  _t432 = 0
  while True:
    if not _tr((1.0 if L_i < L_n else 0.0)): break
    _t433 = (L_p + ((L_stp * L_i) * 4.0))
    _t434 = f_rd_tp(_t433)
    L_c = _t434
    L_num = (L_num + (L_c * _mget(v_rd_tmp + L_i)))
    L_en = (L_en + (L_c * L_c))
    L_i = (L_i + 1.0)
    _t432 += 1
    if _t432 > 1000000: break
  _t437 = L_num
  _t435 = L_en
  _t436 = _sqrt(_t435)
  return _div(_t437, _t436)

def f_rd_pick(L_p0, L_ts, L_ph_prev, L_sn, L_wn, L_rr, L_dir):
  global v_rd_tmp
  L_k = 0.0
  L_n = 0.0
  L_dd = 0.0
  L_best = 0.0
  L_bestd = 0.0
  L_sc = 0.0
  L_st = 0.0
  L_en_ = 0.0
  L_n = 0.0
  L_k = 0.0
  _t438 = 0
  while True:
    if not _tr((1.0 if L_k < L_wn else 0.0)): break
    _t439 = _ix(v_rd_tmp + L_n)
    _t440 = (L_ts + ((L_dir * L_rr) * (L_ph_prev + L_k)))
    _t441 = f_rd_tp(_t440)
    _t442 = _t441
    _mset(_t439, _t442)
    L_n = (L_n + 1.0)
    L_k = (L_k + 4.0)
    _t438 += 1
    if _t438 > 1000000: break
  L_best = (-1000000000.0)
  L_bestd = 0.0
  L_dd = (-L_sn)
  _t443 = 0
  while True:
    if not _tr((1.0 if L_dd <= L_sn else 0.0)): break
    _t444 = (L_p0 + L_dd)
    _t445 = (L_dir * L_rr)
    _t446 = L_n
    _t447 = f_rd_score(_t444, _t445, _t446)
    L_sc = _t447
    if _tr((1.0 if L_sc > L_best else 0.0)):
      L_best = L_sc
      L_bestd = L_dd
      _t448 = L_bestd
    else:
      _t448 = 0.0
    L_dd = (L_dd + 4.0)
    _t443 += 1
    if _t443 > 1000000: break
  L_st = L_bestd
  L_dd = (L_st - 3.0)
  _t449 = 0
  while True:
    if not _tr((1.0 if L_dd <= (L_st + 3.0) else 0.0)): break
    _t450 = 1.0 if _tr((1.0 if L_dd >= (-L_sn) else 0.0)) else 0.0
    if _t450:
      _t450 = 1.0 if _tr((1.0 if L_dd <= L_sn else 0.0)) else 0.0
    if _tr(_t450):
      _t452 = (L_p0 + L_dd)
      _t453 = (L_dir * L_rr)
      _t454 = L_n
      _t455 = f_rd_score(_t452, _t453, _t454)
      L_sc = _t455
      if _tr((1.0 if L_sc > L_best else 0.0)):
        L_best = L_sc
        L_bestd = L_dd
        _t456 = L_bestd
      else:
        _t456 = 0.0
      _t451 = _t456
    else:
      _t451 = 0.0
    L_dd = (L_dd + 1.0)
    _t449 += 1
    if _t449 > 1000000: break
  return L_bestd

def f_dub_grain_tick(L_head, L_rev, L_spawn_ok):
  global v_acc_cur, v_acc_cur_dirty, v_acc_mode, v_acc_set0, v_acc_set1, v_buf_len, v_dens_g, v_dub_align_ms, v_dub_grain_ms, v_dub_pan, v_eff_end, v_eff_start, v_grain_fade, v_ih_l, v_ih_mask, v_ih_n, v_ih_r, v_length, v_max_wgrains, v_pitch_ratio, v_replace_fade, v_sl_gate, v_sm_speed, v_srate, v_state, v_stereo_width, v_wg_c0, v_wg_c1, v_wg_el, v_wg_es, v_wg_fade, v_wg_gl, v_wg_gr, v_wg_hop, v_wg_lcur, v_wg_mem, v_wg_p0, v_wg_p1, v_wg_prev_n, v_wg_prev_ok, v_wg_prev_src, v_wg_rf, v_wg_stride, v_wg_timer
  L_dur = 0.0
  L_hop_t = 0.0
  L_d = 0.0
  L_gi = 0.0
  L_gb = 0.0
  L_fslot = 0.0
  L_ph0 = 0.0
  L_ph1 = 0.0
  L_pn = 0.0
  L_e = 0.0
  L_a = 0.0
  L_b = 0.0
  L_sb = 0.0
  L_pa = 0.0
  L_rr = 0.0
  L_max_l = 0.0
  L_sn = 0.0
  L_wn = 0.0
  L_ln = 0.0
  L_dl = 0.0
  L_s_nom = 0.0
  L_t0 = 0.0
  L_ot = 0.0
  L_src = 0.0
  L_si = 0.0
  L_ip = 0.0
  L_ic = 0.0
  L_dur = ((v_srate * v_dub_grain_ms) * 0.001)
  L_rr = v_pitch_ratio
  if _tr(L_rev):
    _t457 = (-1.0)
  else:
    _t457 = 1.0
  L_d = _t457
  _t460 = ((v_wg_hop * L_dur) * L_rr)
  _t458 = v_sm_speed
  _t459 = max(_t458, 0.0001)
  _t461 = _div(_t460, _t459)
  _t462 = _div(L_dur, (v_max_wgrains - 1.0))
  _t463 = max(_t461, _t462)
  L_hop_t = _t463
  if _tr((1.0 if v_length > 0.0 else 0.0)):
    _t464 = v_length
  else:
    _t464 = v_buf_len
  L_max_l = _t464
  _t465 = v_eff_start
  _t466 = _floor(_t465)
  v_wg_es = _t466
  _t467 = v_eff_end
  _t468 = _floor(_t467)
  _t469 = (_t468 - v_wg_es)
  _t470 = max(_t469, 16.0)
  v_wg_el = _t470
  if _tr(v_acc_cur):
    _t471 = v_acc_set1
  else:
    _t471 = v_acc_set0
  L_sb = _t471
  if _tr((1.0 if abs(v_state - 3.0) < 0.00001 else 0.0)):
    _t472 = 1.0
  else:
    _t472 = 2.0
  v_acc_mode = _t472
  if _tr((1.0 if abs(v_state - 3.0) < 0.00001 else 0.0)):
    _t473 = 1.0
  else:
    _t473 = v_replace_fade
  v_wg_rf = _t473
  v_wg_rf = (v_wg_rf * (v_dens_g * v_sl_gate))
  _t474 = (v_grain_fade * 0.01)
  _t475 = min(0.5, _t474)
  _t476 = _t475
  _t477 = max(0.01, _t476)
  v_wg_fade = _t477
  if _tr((1.0 if v_stereo_width > 0.0001 else 0.0)):
    L_pa = ((((v_dub_pan * v_stereo_width) + 1.0) * 0.25) * 3.141592653589793)
    _t479 = L_pa
    _t480 = math.cos(_t479)
    v_wg_gl = (_t480 * 1.414)
    _t481 = L_pa
    _t482 = math.sin(_t481)
    v_wg_gr = (_t482 * 1.414)
    _t478 = v_wg_gr
  else:
    v_wg_gl = 1.0
    v_wg_gr = 1.0
    _t478 = v_wg_gr
  v_wg_timer = (v_wg_timer + 1.0)
  if _tr((1.0 if v_wg_timer >= L_hop_t else 0.0)):
    v_wg_timer = 0.0
    if _tr(L_spawn_ok):
      L_gi = 0.0
      L_fslot = (-1.0)
      for _t485 in range(max(0, int(v_max_wgrains))):
        L_gb = (v_wg_mem + (L_gi * v_wg_stride))
        _t486 = 1.0 if _tr((1.0 if L_fslot < 0.0 else 0.0)) else 0.0
        if _t486:
          _t486 = 1.0 if _tr((1.0 if abs(_mget(L_gb + 2.0) - 0.0) < 0.00001 else 0.0)) else 0.0
        if _tr(_t486):
          L_fslot = L_gi
          _t487 = L_fslot
        else:
          _t487 = 0.0
        L_gi = (L_gi + 1.0)
      if _tr((1.0 if L_fslot >= 0.0 else 0.0)):
        _t489 = (((v_dub_align_ms * 0.001) * v_srate) + 0.5)
        _t490 = _floor(_t489)
        L_sn = _t490
        _t491 = (0.4 * L_dur)
        _t492 = _floor(_t491)
        _t493 = _t492
        _t494 = min(512.0, _t493)
        L_wn = _t494
        L_ln = 0.0
        L_dl = 0.0
        _t495 = 1.0 if _tr((1.0 if L_sn > 0.0 else 0.0)) else 0.0
        if _t495:
          _t495 = 1.0 if _tr((1.0 if L_wn >= 64.0 else 0.0)) else 0.0
        if _tr(_t495):
          L_ln = (L_sn + L_wn)
          L_s_nom = (v_ih_n - L_ln)
          if _tr(v_wg_prev_ok):
            _t500 = (v_sm_speed * (v_ih_n - v_wg_prev_n))
            _t498 = L_rr
            _t499 = max(_t498, 0.0001)
            _t501 = (_div(_t500, _t499) + 0.5)
            _t502 = _floor(_t501)
            L_ot = _t502
            L_t0 = (v_wg_prev_src + L_ot)
            _t504 = 1.0 if _tr((1.0 if L_ot > 0.0 else 0.0)) else 0.0
            if _t504:
              _t504 = 1.0 if _tr((1.0 if L_ot < (L_dur - L_wn) else 0.0)) else 0.0
            _t503 = 1.0 if _tr(_t504) else 0.0
            if _t503:
              _t503 = 1.0 if _tr((1.0 if (L_t0 + L_wn) <= v_ih_n else 0.0)) else 0.0
            if _tr(_t503):
              _t506 = L_s_nom
              _t507 = L_t0
              _t508 = L_sn
              _t509 = L_wn
              _t510 = f_wg_pick(_t506, _t507, _t508, _t509)
              L_dl = _t510
              _t505 = L_dl
            else:
              _t505 = 0.0
            _t497 = _t505
          else:
            _t497 = 0.0
          _t496 = _t497
        else:
          L_sn = 0.0
          L_s_nom = v_ih_n
          _t496 = L_s_nom
        L_src = (L_s_nom + L_dl)
        v_wg_prev_src = L_src
        v_wg_prev_n = v_ih_n
        v_wg_prev_ok = 1.0
        v_wg_lcur = L_ln
        L_gb = (v_wg_mem + (L_fslot * v_wg_stride))
        _t511 = _ix(L_gb + 0.0)
        _t512 = (L_head - ((L_d * v_sm_speed) * L_ln))
        _mset(_t511, _t512)
        _t513 = _ix(L_gb + 1.0)
        _t514 = 0.0
        _mset(_t513, _t514)
        _t515 = _ix(L_gb + 2.0)
        _t516 = 1.0
        _mset(_t515, _t516)
        _t517 = _ix(L_gb + 3.0)
        _t518 = L_src
        _mset(_t517, _t518)
        _t488 = _t518
      else:
        _t488 = 0.0
      _t484 = _t488
    else:
      _t484 = 0.0
    _t483 = _t484
  else:
    _t483 = 0.0
  L_gi = 0.0
  for _t519 in range(max(0, int(v_max_wgrains))):
    L_gb = (v_wg_mem + (L_gi * v_wg_stride))
    if _tr((1.0 if abs(_mget(L_gb + 2.0) - 1.0) < 0.00001 else 0.0)):
      L_ph0 = _mget(L_gb + 1.0)
      L_ph1 = (L_ph0 + 1.0)
      L_pn = _div((L_ph0 + 0.5), L_dur)
      L_e = 1.0
      if _tr((1.0 if L_pn < v_wg_fade else 0.0)):
        L_e = _div(L_pn, v_wg_fade)
        _t521 = L_e
      else:
        if _tr((1.0 if L_pn > (1.0 - v_wg_fade) else 0.0)):
          L_e = _div((1.0 - L_pn), v_wg_fade)
          _t522 = L_e
        else:
          _t522 = 0.0
        _t521 = _t522
      _t523 = L_e
      _t524 = min(1.0, _t523)
      _t525 = _t524
      _t526 = max(0.0, _t525)
      L_e = _t526
      _t527 = (L_e * 3.141592653589793)
      _t528 = math.cos(_t527)
      L_e = (0.5 - (0.5 * _t528))
      L_a = (_mget(L_gb + 0.0) + ((L_d * L_rr) * L_ph0))
      L_b = (_mget(L_gb + 0.0) + ((L_d * L_rr) * L_ph1))
      L_si = (_mget(L_gb + 3.0) + L_ph0)
      L_ip = float(int((L_si - 1.0)) & int(v_ih_mask))
      L_ic = float(int(L_si) & int(v_ih_mask))
      v_wg_p0 = _mget(v_ih_l + L_ip)
      v_wg_c0 = _mget(v_ih_l + L_ic)
      v_wg_p1 = _mget(v_ih_r + L_ip)
      v_wg_c1 = _mget(v_ih_r + L_ic)
      _t529 = L_a
      _t530 = L_b
      _t531 = L_e
      _t532 = L_sb
      _t533 = f_wg_splat(_t529, _t530, _t531, _t532)
      _t534 = _ix(L_gb + 1.0)
      _t535 = L_ph1
      _mset(_t534, _t535)
      if _tr((1.0 if L_ph1 >= L_dur else 0.0)):
        _t537 = _ix(L_gb + 2.0)
        _t538 = 0.0
        _mset(_t537, _t538)
        _t536 = _t538
      else:
        _t536 = 0.0
      _t520 = _t536
    else:
      _t520 = 0.0
    L_gi = (L_gi + 1.0)
  v_acc_cur_dirty = 1.0
  return v_acc_cur_dirty

def f_dub_merge_cell(L_k, L_sb):
  global v_acc_len, v_acc_wmin, v_acc_wrep, v_cm_mode, v_degradation, v_feedback, v_left_buf, v_right_buf, v_srate, v_tape_lpf_l, v_tape_lpf_l_b, v_tape_lpf_l_c, v_tape_lpf_l_d, v_tape_lpf_r, v_tape_lpf_r_b, v_tape_lpf_r_c, v_tape_lpf_r_d
  L_wv = 0.0
  L_c = 0.0
  L_dubl = 0.0
  L_dubr = 0.0
  L_oldl = 0.0
  L_oldr = 0.0
  L_fb = 0.0
  L_targetl = 0.0
  L_targetr = 0.0
  L_deg = 0.0
  L_deg_amt = 0.0
  L_cutoff = 0.0
  L_lpf_alpha = 0.0
  L_yl_b = 0.0
  L_yr_b = 0.0
  L_w_b = 0.0
  L_drive = 0.0
  L_souffle = 0.0
  L_w_b = (L_sb + (v_acc_len * 2.0))
  L_wv = _mget(L_w_b + L_k)
  if _tr((1.0 if L_wv > 1e-06 else 0.0)):
    L_yl_b = L_sb
    L_yr_b = (L_sb + v_acc_len)
    L_dubl = _div(_mget(L_yl_b + L_k), L_wv)
    L_dubr = _div(_mget(L_yr_b + L_k), L_wv)
    _t540 = _ix(L_yl_b + L_k)
    _t541 = 0.0
    _mset(_t540, _t541)
    _t542 = _ix(L_yr_b + L_k)
    _t543 = 0.0
    _mset(_t542, _t543)
    _t544 = _ix(L_w_b + L_k)
    _t545 = 0.0
    _mset(_t544, _t545)
    L_oldl = _mget(v_left_buf + L_k)
    L_oldr = _mget(v_right_buf + L_k)
    if _tr((1.0 if abs(v_cm_mode - 2.0) < 0.00001 else 0.0)):
      _t547 = _div(L_wv, v_acc_wrep)
      _t548 = min(1.0, _t547)
      L_c = _t548
      L_targetl = ((L_oldl * (1.0 - L_c)) + (L_dubl * L_c))
      L_targetr = ((L_oldr * (1.0 - L_c)) + (L_dubr * L_c))
      _t546 = L_targetr
    else:
      _t549 = _div(L_wv, v_acc_wmin)
      _t550 = min(1.0, _t549)
      L_c = _t550
      L_fb = (1.0 - (L_c * (1.0 - v_feedback)))
      L_targetl = ((L_oldl * L_fb) + (L_dubl * L_c))
      L_targetr = ((L_oldr * L_fb) + (L_dubr * L_c))
      _t546 = L_targetr
    L_deg = v_degradation
    _t551 = 1.0 if _tr((1.0 if L_deg > 0.0001 else 0.0)) else 0.0
    if _t551:
      _t552 = (v_feedback - 1.0)
      _t553 = abs(_t552)
      _t551 = 1.0 if _tr((1.0 if _t553 > 0.001 else 0.0)) else 0.0
    if _tr(_t551):
      _t557 = L_deg
      _t555 = (v_feedback - 1.0)
      _t556 = abs(_t555)
      L_deg_amt = (_t557 * _t556)
      L_drive = (1.0 + (L_deg_amt * 4.0))
      _t558 = (L_targetl * L_drive)
      _t559 = f_fast_tanh(_t558)
      L_targetl = _div(_t559, L_drive)
      _t560 = (L_targetr * L_drive)
      _t561 = f_fast_tanh(_t560)
      L_targetr = _div(_t561, L_drive)
      _t562 = ((-3.2) * L_deg_amt)
      _t563 = _exp(_t562)
      _t564 = (20000.0 * _t563)
      _t565 = max(200.0, _t564)
      L_cutoff = _t565
      _t566 = _div((((-2.0) * 3.141592653589793) * L_cutoff), v_srate)
      _t567 = _exp(_t566)
      L_lpf_alpha = (1.0 - _t567)
      v_tape_lpf_l = (v_tape_lpf_l + (L_lpf_alpha * (L_targetl - v_tape_lpf_l)))
      v_tape_lpf_l_b = (v_tape_lpf_l_b + (L_lpf_alpha * (v_tape_lpf_l - v_tape_lpf_l_b)))
      v_tape_lpf_l_c = (v_tape_lpf_l_c + (L_lpf_alpha * (v_tape_lpf_l_b - v_tape_lpf_l_c)))
      v_tape_lpf_l_d = (v_tape_lpf_l_d + (L_lpf_alpha * (v_tape_lpf_l_c - v_tape_lpf_l_d)))
      v_tape_lpf_r = (v_tape_lpf_r + (L_lpf_alpha * (L_targetr - v_tape_lpf_r)))
      v_tape_lpf_r_b = (v_tape_lpf_r_b + (L_lpf_alpha * (v_tape_lpf_r - v_tape_lpf_r_b)))
      v_tape_lpf_r_c = (v_tape_lpf_r_c + (L_lpf_alpha * (v_tape_lpf_r_b - v_tape_lpf_r_c)))
      v_tape_lpf_r_d = (v_tape_lpf_r_d + (L_lpf_alpha * (v_tape_lpf_r_c - v_tape_lpf_r_d)))
      L_targetl = ((L_targetl * (1.0 - L_deg_amt)) + (v_tape_lpf_l_d * L_deg_amt))
      L_targetr = ((L_targetr * (1.0 - L_deg_amt)) + (v_tape_lpf_r_d * L_deg_amt))
      _t568 = _rand(2.0)
      L_souffle = (((_t568 - 1.0) * 0.0001) * L_deg_amt)
      L_targetl = (L_targetl + L_souffle)
      L_targetr = (L_targetr + L_souffle)
      _t554 = L_targetr
    else:
      _t554 = 0.0
    _t569 = _ix(v_left_buf + L_k)
    _t570 = L_targetl
    _mset(_t569, _t570)
    _t571 = _ix(v_right_buf + L_k)
    _t572 = L_targetr
    _mset(_t571, _t572)
    _t539 = _t572
  else:
    _t539 = 0.0
  return _t539

def f_dub_commit_step(L_n):
  global v_cm_active, v_cm_dir, v_cm_hi, v_cm_k, v_cm_lo, v_cm_sb
  L_cnt = 0.0
  L_cnt = 0.0
  _t573 = 0
  while True:
    _t574 = 1.0 if _tr(v_cm_active) else 0.0
    if _t574:
      _t574 = 1.0 if _tr((1.0 if L_cnt < L_n else 0.0)) else 0.0
    if not _tr(_t574): break
    _t575 = v_cm_k
    _t576 = v_cm_sb
    _t577 = f_dub_merge_cell(_t575, _t576)
    v_cm_k = (v_cm_k + v_cm_dir)
    _t578 = 1.0 if _tr((1.0 if v_cm_k < v_cm_lo else 0.0)) else 0.0
    if not _t578:
      _t578 = 1.0 if _tr((1.0 if v_cm_k >= v_cm_hi else 0.0)) else 0.0
    if _tr(_t578):
      v_cm_active = 0.0
      _t579 = v_cm_active
    else:
      _t579 = 0.0
    L_cnt = (L_cnt + 1.0)
    _t573 += 1
    if _t573 > 1000000: break
  return 0.0

def f_dub_commit_begin(L_fwd):
  global v_acc_cur, v_acc_cur_dirty, v_acc_hi, v_acc_lo, v_acc_mode, v_acc_set0, v_acc_set1, v_cm_active, v_cm_dir, v_cm_hi, v_cm_k, v_cm_lo, v_cm_mode, v_cm_sb
  _t580 = 0
  while True:
    if not _tr(v_cm_active): break
    _t581 = f_dub_commit_step(262144.0)
    _t580 += 1
    if _t580 > 1000000: break
  _t582 = 1.0 if _tr(v_acc_cur_dirty) else 0.0
  if _t582:
    _t582 = 1.0 if _tr((1.0 if v_acc_hi >= v_acc_lo else 0.0)) else 0.0
  if _tr(_t582):
    if _tr(v_acc_cur):
      _t584 = v_acc_set1
    else:
      _t584 = v_acc_set0
    v_cm_sb = _t584
    v_cm_mode = v_acc_mode
    v_cm_lo = v_acc_lo
    v_cm_hi = (v_acc_hi + 1.0)
    if _tr(L_fwd):
      _t585 = 1.0
    else:
      _t585 = (-1.0)
    v_cm_dir = _t585
    if _tr(L_fwd):
      _t586 = v_cm_lo
    else:
      _t586 = v_acc_hi
    v_cm_k = _t586
    v_cm_active = 1.0
    v_acc_cur = (1.0 - v_acc_cur)
    _t583 = v_acc_cur
  else:
    _t583 = 0.0
  v_acc_cur_dirty = 0.0
  v_acc_lo = 1000000000.0
  v_acc_hi = (-1.0)
  return v_acc_hi

def f_dub_merge_behind(L_head):
  global v_acc_cur, v_acc_cur_dirty, v_acc_hi, v_acc_lo, v_acc_set0, v_acc_set1, v_cm_active, v_delay_len, v_dub_grain_ms, v_pitch_ratio, v_sm_speed, v_srate, v_wg_lcur
  L_margin = 0.0
  L_safe_hi = 0.0
  L_k = 0.0
  L_sb = 0.0
  L_n = 0.0
  _t588 = 1.0 if _tr(v_acc_cur_dirty) else 0.0
  if _t588:
    _t588 = 1.0 if _tr((0.0 if _tr(v_cm_active) else 1.0)) else 0.0
  _t587 = 1.0 if _tr(_t588) else 0.0
  if _t587:
    _t587 = 1.0 if _tr((1.0 if v_acc_hi >= v_acc_lo else 0.0)) else 0.0
  if _tr(_t587):
    _t594 = ((v_srate * v_dub_grain_ms) * 0.001)
    _t590 = v_pitch_ratio
    _t591 = abs(_t590)
    _t592 = _t591
    _t593 = max(1.0, _t592)
    _t600 = (((_t594 * _t593) + v_delay_len) + 32.0)
    _t599 = v_wg_lcur
    _t595 = v_sm_speed
    _t596 = abs(_t595)
    _t597 = _t596
    _t598 = max(1.0, _t597)
    _t601 = (_t600 + (_t599 * _t598))
    _t602 = _floor(_t601)
    _t603 = _t602
    _t604 = max(64.0, _t603)
    L_margin = _t604
    _t605 = L_head
    _t606 = _floor(_t605)
    L_safe_hi = (_t606 - L_margin)
    if _tr((1.0 if L_safe_hi > v_acc_lo else 0.0)):
      if _tr(v_acc_cur):
        _t608 = v_acc_set1
      else:
        _t608 = v_acc_set0
      L_sb = _t608
      L_k = v_acc_lo
      L_n = 0.0
      _t609 = 0
      while True:
        _t611 = 1.0 if _tr((1.0 if L_k < L_safe_hi else 0.0)) else 0.0
        if _t611:
          _t611 = 1.0 if _tr((1.0 if L_k <= v_acc_hi else 0.0)) else 0.0
        _t610 = 1.0 if _tr(_t611) else 0.0
        if _t610:
          _t610 = 1.0 if _tr((1.0 if L_n < 64.0 else 0.0)) else 0.0
        if not _tr(_t610): break
        _t612 = L_k
        _t613 = L_sb
        _t614 = f_dub_merge_cell(_t612, _t613)
        L_k = (L_k + 1.0)
        L_n = (L_n + 1.0)
        _t609 += 1
        if _t609 > 1000000: break
      v_acc_lo = L_k
      if _tr((1.0 if v_acc_lo > v_acc_hi else 0.0)):
        v_acc_cur_dirty = 0.0
        v_acc_lo = 1000000000.0
        v_acc_hi = (-1.0)
        _t615 = v_acc_hi
      else:
        _t615 = 0.0
      _t607 = _t615
    else:
      _t607 = 0.0
    _t589 = _t607
  else:
    _t589 = 0.0
  return _t589

def f_dub_flush():
  global v_cm_active, v_max_wgrains, v_wg_mem, v_wg_prev_ok, v_wg_stride, v_wg_timer
  L_gi = 0.0
  L_gb = 0.0
  _t616 = f_dub_commit_begin(1.0)
  _t617 = 0
  while True:
    if not _tr(v_cm_active): break
    _t618 = f_dub_commit_step(262144.0)
    _t617 += 1
    if _t617 > 1000000: break
  L_gi = 0.0
  for _t619 in range(max(0, int(v_max_wgrains))):
    L_gb = (v_wg_mem + (L_gi * v_wg_stride))
    _t620 = _ix(L_gb + 2.0)
    _t621 = 0.0
    _mset(_t620, _t621)
    L_gi = (L_gi + 1.0)
  v_wg_timer = 0.0
  v_wg_prev_ok = 0.0
  return v_wg_prev_ok

def f_dub_discard():
  global v_acc_cur_dirty, v_acc_hi, v_acc_lo, v_acc_ok, v_acc_set0, v_acc_size, v_cm_active, v_max_wgrains, v_wg_mem, v_wg_prev_ok, v_wg_stride, v_wg_timer
  L_gi = 0.0
  L_gb = 0.0
  _t622 = 1.0 if _tr(v_acc_ok) else 0.0
  if _t622:
    _t623 = 1.0 if _tr(v_acc_cur_dirty) else 0.0
    if not _t623:
      _t623 = 1.0 if _tr(v_cm_active) else 0.0
    _t622 = 1.0 if _tr(_t623) else 0.0
  if _tr(_t622):
    _t625 = v_acc_set0
    _t626 = (v_acc_size * 2.0)
    _t627 = _memset(_t625, 0.0, _t626)
    _t624 = _t627
  else:
    _t624 = 0.0
  v_cm_active = 0.0
  v_acc_cur_dirty = 0.0
  v_acc_lo = 1000000000.0
  v_acc_hi = (-1.0)
  L_gi = 0.0
  for _t628 in range(max(0, int(v_max_wgrains))):
    L_gb = (v_wg_mem + (L_gi * v_wg_stride))
    _t629 = _ix(L_gb + 2.0)
    _t630 = 0.0
    _mset(_t629, _t630)
    L_gi = (L_gi + 1.0)
  v_wg_timer = 0.0
  v_wg_prev_ok = 0.0
  return v_wg_prev_ok

def f_ref_host_phase():
  global v_qs_b0, v_qs_i, v_srate, v_tempo, v_ts_num
  L_bl = 0.0
  L_nb = 0.0
  L_b = 0.0
  _t633 = (v_srate * 60.0)
  _t631 = v_tempo
  _t632 = max(_t631, 20.0)
  L_bl = _div(_t633, _t632)
  if _tr((1.0 if v_ts_num > 0.0 else 0.0)):
    _t634 = v_ts_num
  else:
    _t634 = 4.0
  L_nb = _t634
  L_b = (v_qs_b0 + _div((v_qs_i * v_tempo), (60.0 * v_srate)))
  _t637 = L_nb
  _t635 = _div(L_b, L_nb)
  _t636 = _floor(_t635)
  L_b = (L_b - (_t637 * _t636))
  return (L_b * L_bl)

def f_sy_is_master(L_idx):
  global v_gmem, v_instance_alias, v_instance_id
  L_o = 0.0
  L_o = (L_idx * 10.0)
  _t638 = 1.0 if _tr((1.0 if abs(_gget(L_o) - 1.0) < 0.00001 else 0.0)) else 0.0
  if _t638:
    _t639 = 1.0 if _tr((1.0 if abs(_gget((L_o + 1.0)) - v_instance_id) < 0.00001 else 0.0)) else 0.0
    if not _t639:
      _t639 = 1.0 if _tr((1.0 if abs(_gget((L_o + 1.0)) - v_instance_alias) < 0.00001 else 0.0)) else 0.0
    _t638 = 1.0 if _tr(_t639) else 0.0
  return _t638

def f_sy_make_own(L_idx, L_base):
  global v_instance_id, v_part_sm, v_part_sp, v_part_sref
  _t640 = _ix(v_part_sp + L_idx)
  _t641 = 0.0
  _mset(_t640, _t641)
  _t642 = _ix(v_part_sref + L_idx)
  _t643 = _time()
  _t644 = (_t643 * 1000.0)
  _t645 = _floor(_t644)
  _t646 = ((_mod(_t645, 1000000.0) * 10.0) + v_instance_id)
  _mset(_t642, _t646)
  _t647 = _ix(v_part_sm + L_idx)
  _t648 = L_base
  _mset(_t647, _t648)
  return _t648

def f_sy_master_blk(L_idx):
  global v_gmem
  L_mid = 0.0
  L_k = 0.0
  L_r = 0.0
  L_mid = _gget(((L_idx * 10.0) + 1.0))
  L_r = (-1.0)
  L_k = 0.0
  for _t649 in range(max(0, int(8.0))):
    if _tr((1.0 if abs(_gget(((1000.0 + (L_k * 600.0)) + 1.0)) - L_mid) < 0.00001 else 0.0)):
      L_r = ((1000.0 + (L_k * 600.0)) + (L_idx * 200.0))
      _t650 = L_r
    else:
      _t650 = 0.0
    L_k = (L_k + 1.0)
  return L_r

def f_sy_pos(L_idx, L_plen):
  global v_part_sp
  if _tr((1.0 if L_plen > 0.0 else 0.0)):
    _t651 = _mget(v_part_sp + L_idx)
  else:
    _t651 = (-1.0)
  return _t651

def f_sy_id(L_idx, L_plen):
  global v_part_sp, v_part_sref
  _t652 = 1.0 if _tr((1.0 if L_plen > 0.0 else 0.0)) else 0.0
  if _t652:
    _t652 = 1.0 if _tr((1.0 if _mget(v_part_sp + L_idx) >= 0.0 else 0.0)) else 0.0
  if _tr(_t652):
    _t653 = _mget(v_part_sref + L_idx)
  else:
    _t653 = 0.0
  return _t653

def f_sy_len(L_idx, L_plen, L_pbase):
  global v_part_sm, v_part_sp
  _t654 = 1.0 if _tr((1.0 if L_plen > 0.0 else 0.0)) else 0.0
  if _t654:
    _t654 = 1.0 if _tr((1.0 if _mget(v_part_sp + L_idx) >= 0.0 else 0.0)) else 0.0
  if _tr(_t654):
    _t655 = _mget(v_part_sm + L_idx)
  else:
    _t655 = 0.0
  return _t655

def f_sy_live(L_idx, L_plen):
  global v_gmem, v_part_sp, v_part_sref
  L_o = 0.0
  L_bk = 0.0
  L_o = (L_idx * 10.0)
  _t656 = 1.0 if _tr((1.0 if L_plen > 0.0 else 0.0)) else 0.0
  if _t656:
    _t656 = 1.0 if _tr((1.0 if _mget(v_part_sp + L_idx) >= 0.0 else 0.0)) else 0.0
  if _tr(_t656):
    _t658 = L_idx
    _t659 = f_sy_is_master(_t658)
    if _tr(_t659):
      _t660 = 1.0
    else:
      if _tr((1.0 if abs(_mget(v_part_sref + L_idx) - 9.0) < 0.00001 else 0.0)):
        _t661 = (1.0 if abs(_gget(L_o) - 2.0) < 0.00001 else 0.0)
      else:
        if _tr((1.0 if abs(_gget(L_o) - 1.0) < 0.00001 else 0.0)):
          _t663 = L_idx
          _t664 = f_sy_master_blk(_t663)
          L_bk = _t664
          _t665 = 1.0 if _tr((1.0 if L_bk >= 0.0 else 0.0)) else 0.0
          if _t665:
            _t665 = 1.0 if _tr((1.0 if abs(_gget((L_bk + 183.0)) - _mget(v_part_sref + L_idx)) < 0.00001 else 0.0)) else 0.0
          _t662 = _t665
        else:
          _t662 = 0.0
        _t661 = _t662
      _t660 = _t661
    _t657 = _t660
  else:
    _t657 = 0.0
  return _t657

def f_sy_clear(L_idx):
  global v_part_sep, v_part_sm, v_part_sp, v_part_sref
  _t666 = _ix(v_part_sp + L_idx)
  _t667 = (-1.0)
  _mset(_t666, _t667)
  _t668 = _ix(v_part_sref + L_idx)
  _t669 = 0.0
  _mset(_t668, _t669)
  _t670 = _ix(v_part_sm + L_idx)
  _t671 = 0.0
  _mset(_t670, _t671)
  _t672 = _ix(v_part_sep + L_idx)
  _t673 = 0.0
  _mset(_t672, _t673)
  return _t673

def f_x_adopt(L_src):
  global v_active_part, v_gmem, v_length, v_part_sep, v_part_sm, v_part_sp, v_part_sref
  L_bk = 0.0
  L_idx = 0.0
  L_idx = (v_active_part - 1.0)
  _t674 = (L_src + 0.5)
  _t675 = _floor(_t674)
  L_src = _t675
  _t677 = 1.0 if _tr((1.0 if L_src >= 1.0 else 0.0)) else 0.0
  if _t677:
    _t677 = 1.0 if _tr((1.0 if L_src <= 8.0 else 0.0)) else 0.0
  _t676 = 1.0 if _tr(_t677) else 0.0
  if _t676:
    _t676 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
  if _tr(_t676):
    L_bk = ((1000.0 + ((L_src - 1.0) * 600.0)) + (L_idx * 200.0))
    if _tr((1.0 if _gget((L_bk + 183.0)) > 0.0 else 0.0)):
      _t680 = _ix(v_part_sp + L_idx)
      _t681 = 0.0
      _mset(_t680, _t681)
      _t682 = _ix(v_part_sref + L_idx)
      _t683 = _gget((L_bk + 183.0))
      _mset(_t682, _t683)
      _t684 = _ix(v_part_sm + L_idx)
      if _tr((1.0 if _gget((L_bk + 184.0)) > 0.0 else 0.0)):
        _t685 = _gget((L_bk + 184.0))
      else:
        _t685 = v_length
      _t686 = _t685
      _mset(_t684, _t686)
      _t687 = _ix(v_part_sep + L_idx)
      if _tr((1.0 if abs(_mget(v_part_sref + L_idx) - 9.0) < 0.00001 else 0.0)):
        _t688 = _gget((914.0 + L_idx))
      else:
        _t688 = 0.0
      _t689 = _t688
      _mset(_t687, _t689)
      _t679 = _t689
    else:
      _t679 = 0.0
    _t678 = _t679
  else:
    _t678 = 0.0
  return _t678

def f_x_select_mode():
  global v_active_part, v_base_loop_length, v_gmem, v_length, v_mclk_len, v_mclk_valid, v_part_sp, v_play_state, v_x_mode, v_x_ms, v_x_per
  L_xi_b = 0.0
  L_xmb = 0.0
  L_xi_b = (v_active_part - 1.0)
  v_x_mode = 0.0
  _t690 = L_xi_b
  _t691 = f_sy_is_master(_t690)
  if _tr(_t691):
    v_x_mode = 2.0
    v_x_ms = _mget(v_part_sp + L_xi_b)
    if _tr((1.0 if v_base_loop_length > 0.0 else 0.0)):
      _t693 = v_base_loop_length
    else:
      _t693 = v_length
    v_x_per = _t693
    _t692 = v_x_per
  else:
    _t694 = 1.0 if _tr((1.0 if abs(_gget(((v_active_part - 1.0) * 10.0)) - 1.0) < 0.00001 else 0.0)) else 0.0
    if _t694:
      _t694 = 1.0 if _tr(v_mclk_valid) else 0.0
    if _tr(_t694):
      _t696 = L_xi_b
      _t697 = f_sy_master_blk(_t696)
      L_xmb = _t697
      if _tr((1.0 if L_xmb >= 0.0 else 0.0)):
        v_x_mode = 1.0
        _t699 = _gget((L_xmb + 182.0))
        _t700 = max(0.0, _t699)
        v_x_ms = _t700
        v_x_per = v_mclk_len
        _t698 = v_x_per
      else:
        _t698 = 0.0
      _t695 = _t698
    else:
      _t701 = 1.0 if _tr((1.0 if abs(_gget(((v_active_part - 1.0) * 10.0)) - 2.0) < 0.00001 else 0.0)) else 0.0
      if _t701:
        _t701 = 1.0 if _tr(float(int(v_play_state) & int(1.0))) else 0.0
      if _tr(_t701):
        v_x_mode = 3.0
        v_x_ms = 0.0
        _t703 = f_host_measure_len()
        v_x_per = _t703
        _t702 = v_x_per
      else:
        _t702 = 0.0
      _t695 = _t702
    _t692 = _t695
  return _t692

def f_x_arm(L_mode):
  global v_active_part, v_length, v_state, v_x_event, v_x_part, v_x_ph_prev, v_xarm
  v_x_part = v_active_part
  v_x_ph_prev = (-1.0)
  v_x_event = 0.0
  if _tr((1.0 if abs(L_mode - 1.0) < 0.00001 else 0.0)):
    _t706 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
    if _t706:
      _t706 = 1.0 if _tr((0.0 if abs(v_state - 0.0) < 0.00001 else 1.0)) else 0.0
    _t705 = 1.0 if _tr(_t706) else 0.0
    if _t705:
      _t705 = 1.0 if _tr((0.0 if abs(v_state - 7.0) < 0.00001 else 1.0)) else 0.0
    if _tr(_t705):
      _t707 = 1.0
    else:
      _t707 = 0.0
    v_xarm = _t707
    _t704 = v_xarm
  else:
    if _tr((1.0 if abs(L_mode - 2.0) < 0.00001 else 0.0)):
      _t709 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
      if _t709:
        _t710 = 1.0 if _tr((1.0 if abs(v_state - 0.0) < 0.00001 else 0.0)) else 0.0
        if not _t710:
          _t710 = 1.0 if _tr((1.0 if abs(v_state - 7.0) < 0.00001 else 0.0)) else 0.0
        _t709 = 1.0 if _tr(_t710) else 0.0
      if _tr(_t709):
        _t711 = 2.0
      else:
        _t711 = 0.0
      v_xarm = _t711
      _t708 = v_xarm
    else:
      if _tr((1.0 if abs(L_mode - 3.0) < 0.00001 else 0.0)):
        _t713 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
        if _t713:
          _t714 = 1.0 if _tr((1.0 if abs(v_state - 0.0) < 0.00001 else 0.0)) else 0.0
          if not _t714:
            _t714 = 1.0 if _tr((1.0 if abs(v_state - 7.0) < 0.00001 else 0.0)) else 0.0
          _t713 = 1.0 if _tr(_t714) else 0.0
        if _tr(_t713):
          _t715 = 3.0
        else:
          _t715 = 0.0
        v_xarm = _t715
        _t712 = v_xarm
      else:
        if _tr((1.0 if abs(L_mode - 4.0) < 0.00001 else 0.0)):
          _t717 = 1.0 if _tr((1.0 if v_length <= 0.0 else 0.0)) else 0.0
          if _t717:
            _t717 = 1.0 if _tr((1.0 if abs(v_state - 0.0) < 0.00001 else 0.0)) else 0.0
          if _tr(_t717):
            _t718 = 4.0
          else:
            _t718 = 0.0
          v_xarm = _t718
          _t716 = v_xarm
        else:
          v_xarm = 0.0
          _t716 = v_xarm
        _t712 = _t716
      _t708 = _t712
    _t704 = _t708
  if _tr((0.0 if abs(v_xarm - 0.0) < 0.00001 else 1.0)):
    _t720 = f_x_select_mode()
    _t719 = _t720
  else:
    _t719 = 0.0
  return _t719

def f_rec_ref_capture():
  global v_active_part, v_gmem, v_instance_alias, v_instance_id, v_mclk_pos, v_mclk_valid, v_play_state, v_rec_force_free, v_rec_ref_id, v_rec_ref_kind, v_rec_ref_len, v_rec_ref_ph
  L_ms_off = 0.0
  L_locked = 0.0
  L_mid = 0.0
  L_is_self = 0.0
  L_mb = 0.0
  L_ms_s = 0.0
  v_rec_ref_kind = 0.0
  v_rec_ref_id = 0.0
  v_rec_ref_len = 0.0
  v_rec_ref_ph = 0.0
  L_ms_off = ((v_active_part - 1.0) * 10.0)
  L_locked = _gget(L_ms_off)
  L_mid = _gget((L_ms_off + 1.0))
  _t721 = 1.0 if _tr((1.0 if abs(L_locked - 1.0) < 0.00001 else 0.0)) else 0.0
  if _t721:
    _t722 = 1.0 if _tr((1.0 if abs(L_mid - v_instance_id) < 0.00001 else 0.0)) else 0.0
    if not _t722:
      _t722 = 1.0 if _tr((1.0 if abs(L_mid - v_instance_alias) < 0.00001 else 0.0)) else 0.0
    _t721 = 1.0 if _tr(_t722) else 0.0
  L_is_self = _t721
  _t723 = 1.0 if _tr((1.0 if abs(L_locked - 2.0) < 0.00001 else 0.0)) else 0.0
  if _t723:
    _t723 = 1.0 if _tr(float(int(v_play_state) & int(1.0))) else 0.0
  if _tr(_t723):
    v_rec_ref_kind = 2.0
    v_rec_ref_id = 9.0
    _t725 = f_host_measure_len()
    v_rec_ref_len = _t725
    _t726 = f_ref_host_phase()
    v_rec_ref_ph = _t726
    _t724 = v_rec_ref_ph
  else:
    _t728 = 1.0 if _tr((1.0 if abs(L_locked - 1.0) < 0.00001 else 0.0)) else 0.0
    if _t728:
      _t728 = 1.0 if _tr((0.0 if _tr(L_is_self) else 1.0)) else 0.0
    _t727 = 1.0 if _tr(_t728) else 0.0
    if _t727:
      _t727 = 1.0 if _tr((1.0 if _gget((L_ms_off + 2.0)) > 0.0 else 0.0)) else 0.0
    if _tr(_t727):
      _t730 = (v_active_part - 1.0)
      _t731 = f_sy_master_blk(_t730)
      L_mb = _t731
      v_rec_ref_kind = 1.0
      _t732 = 1.0 if _tr((1.0 if L_mb >= 0.0 else 0.0)) else 0.0
      if _t732:
        _t732 = 1.0 if _tr((1.0 if _gget((L_mb + 183.0)) > 0.0 else 0.0)) else 0.0
      if _tr(_t732):
        _t733 = _gget((L_mb + 183.0))
      else:
        _t733 = L_mid
      v_rec_ref_id = _t733
      _t734 = 1.0 if _tr((1.0 if L_mb >= 0.0 else 0.0)) else 0.0
      if _t734:
        _t734 = 1.0 if _tr((1.0 if _gget((L_mb + 182.0)) > 0.0 else 0.0)) else 0.0
      if _tr(_t734):
        _t735 = _gget((L_mb + 182.0))
      else:
        _t735 = 0.0
      L_ms_s = _t735
      v_rec_ref_len = _gget((L_ms_off + 2.0))
      _t736 = 1.0 if _tr((1.0 if L_mb >= 0.0 else 0.0)) else 0.0
      if _t736:
        _t736 = 1.0 if _tr((1.0 if _gget((L_mb + 184.0)) > 0.0 else 0.0)) else 0.0
      if _tr(_t736):
        _t738 = v_rec_ref_len
        _t739 = _gget((L_mb + 184.0))
        _t740 = min(_t738, _t739)
        v_rec_ref_len = _t740
        _t737 = v_rec_ref_len
      else:
        _t737 = 0.0
      if _tr(v_mclk_valid):
        _t741 = v_mclk_pos
      else:
        _t741 = _gget((L_ms_off + 3.0))
      v_rec_ref_ph = (_t741 - L_ms_s)
      _t729 = v_rec_ref_ph
    else:
      _t729 = 0.0
    _t724 = _t729
  if _tr((1.0 if v_rec_ref_kind > 0.0 else 0.0)):
    _t745 = v_rec_ref_len
    _t743 = _div(v_rec_ref_ph, v_rec_ref_len)
    _t744 = _floor(_t743)
    v_rec_ref_ph = (v_rec_ref_ph - (_t745 * _t744))
    _t742 = v_rec_ref_ph
  else:
    _t742 = 0.0
  if _tr(v_rec_force_free):
    v_rec_ref_kind = 0.0
    v_rec_force_free = 0.0
    _t746 = v_rec_force_free
  else:
    _t746 = 0.0
  return _t746

def f_rec_ref_snap():
  global v_qs_frac, v_qs_mode, v_qs_unit, v_rec_ref_kind, v_rec_ref_len, v_rec_ref_ph, v_srate, v_tempo
  L_g = 0.0
  if _tr((1.0 if v_rec_ref_kind > 0.0 else 0.0)):
    if _tr((1.0 if abs(v_qs_mode - 1.0) < 0.00001 else 0.0)):
      _t751 = ((v_qs_unit * 60.0) * v_srate)
      _t749 = v_tempo
      _t750 = max(_t749, 20.0)
      _t748 = _div(_t751, _t750)
    else:
      _t748 = v_qs_unit
    L_g = _t748
    if _tr(v_qs_frac):
      L_g = (L_g * 0.125)
      _t752 = L_g
    else:
      _t752 = 0.0
    if _tr((1.0 if L_g > 1.0 else 0.0)):
      _t754 = (_div(v_rec_ref_ph, L_g) + 0.5)
      _t755 = _floor(_t754)
      v_rec_ref_ph = (_t755 * L_g)
      if _tr((1.0 if v_rec_ref_ph >= v_rec_ref_len else 0.0)):
        v_rec_ref_ph = (v_rec_ref_ph - v_rec_ref_len)
        _t756 = v_rec_ref_ph
      else:
        _t756 = 0.0
      _t753 = _t756
    else:
      _t753 = 0.0
    _t747 = _t753
  else:
    _t747 = 0.0
  return _t747

def f_sync_store(L_idx):
  global v_gmem, v_length, v_part_sep, v_part_sm, v_part_sp, v_part_sref, v_rec_ref_id, v_rec_ref_kind, v_rec_ref_len, v_rec_ref_ph
  L_t = 0.0
  L_s = 0.0
  _t758 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
  if _t758:
    _t758 = 1.0 if _tr((1.0 if v_rec_ref_kind > 0.0 else 0.0)) else 0.0
  _t757 = 1.0 if _tr(_t758) else 0.0
  if _t757:
    _t757 = 1.0 if _tr((1.0 if v_rec_ref_len > 0.0 else 0.0)) else 0.0
  if _tr(_t757):
    L_t = (v_rec_ref_len - v_rec_ref_ph)
    _t762 = v_rec_ref_len
    _t760 = _div(L_t, v_rec_ref_len)
    _t761 = _floor(_t760)
    L_t = (L_t - (_t762 * _t761))
    _t766 = L_t
    _t765 = v_length
    _t763 = _div(L_t, v_length)
    _t764 = _floor(_t763)
    L_s = (_t766 - (_t765 * _t764))
    _t767 = _ix(v_part_sp + L_idx)
    _t768 = L_s
    _mset(_t767, _t768)
    _t769 = _ix(v_part_sref + L_idx)
    _t770 = v_rec_ref_id
    _mset(_t769, _t770)
    _t771 = _ix(v_part_sm + L_idx)
    _t772 = v_rec_ref_len
    _mset(_t771, _t772)
    _t773 = _ix(v_part_sep + L_idx)
    if _tr((1.0 if abs(v_rec_ref_kind - 2.0) < 0.00001 else 0.0)):
      _t774 = _gget((914.0 + L_idx))
    else:
      _t774 = 0.0
    _t775 = _t774
    _mset(_t773, _t775)
    _t759 = _t775
  else:
    _t759 = 0.0
  v_rec_ref_kind = 0.0
  return v_rec_ref_kind

def f_rp_check():
  global v_active_part, v_gmem, v_length, v_master_pos, v_master_pos1, v_master_pos2, v_master_pos3, v_part_sep, v_part_sm, v_part_sp, v_part_sref, v_play_state, v_rp_cnt, v_rp_part, v_rp_pend, v_srate, v_state, v_sync_hard_resync
  L_idx = 0.0
  L_m = 0.0
  L_p = 0.0
  L_n = 0.0
  L_ok = 0.0
  L_thr = 0.0
  L_ph = 0.0
  L_e = 0.0
  L_idx = (v_active_part - 1.0)
  L_ok = 0.0
  L_p = 1.0
  if _tr((0.0 if abs(v_rp_part - v_active_part) < 0.00001 else 1.0)):
    v_rp_pend = 0.0
    v_rp_cnt = 0.0
    v_rp_part = v_active_part
    _t776 = v_rp_part
  else:
    _t776 = 0.0
  _t786 = 1.0 if _tr((1.0 if _gget(93.0) > 0.5 else 0.0)) else 0.0
  if _t786:
    _t786 = 1.0 if _tr(float(int(v_play_state) & int(1.0))) else 0.0
  _t785 = 1.0 if _tr(_t786) else 0.0
  if _t785:
    _t785 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
  _t784 = 1.0 if _tr(_t785) else 0.0
  if _t784:
    _t784 = 1.0 if _tr((1.0 if L_idx >= 0.0 else 0.0)) else 0.0
  _t783 = 1.0 if _tr(_t784) else 0.0
  if _t783:
    _t783 = 1.0 if _tr((1.0 if L_idx < 3.0 else 0.0)) else 0.0
  _t782 = 1.0 if _tr(_t783) else 0.0
  if _t782:
    _t782 = 1.0 if _tr((1.0 if abs(_gget((L_idx * 10.0)) - 2.0) < 0.00001 else 0.0)) else 0.0
  _t781 = 1.0 if _tr(_t782) else 0.0
  if _t781:
    _t781 = 1.0 if _tr((1.0 if abs(_mget(v_part_sref + L_idx) - 9.0) < 0.00001 else 0.0)) else 0.0
  _t780 = 1.0 if _tr(_t781) else 0.0
  if _t780:
    _t780 = 1.0 if _tr((1.0 if _mget(v_part_sp + L_idx) >= 0.0 else 0.0)) else 0.0
  _t779 = 1.0 if _tr(_t780) else 0.0
  if _t779:
    _t779 = 1.0 if _tr((1.0 if _gget((914.0 + L_idx)) > 0.0 else 0.0)) else 0.0
  _t778 = 1.0 if _tr(_t779) else 0.0
  if _t778:
    _t778 = 1.0 if _tr((1.0 if abs(_mget(v_part_sep + L_idx) - _gget((914.0 + L_idx))) < 0.00001 else 0.0)) else 0.0
  _t777 = 1.0 if _tr(_t778) else 0.0
  if _t777:
    _t790 = 1.0 if _tr((1.0 if abs(v_state - 0.0) < 0.00001 else 0.0)) else 0.0
    if not _t790:
      _t790 = 1.0 if _tr((1.0 if abs(v_state - 2.0) < 0.00001 else 0.0)) else 0.0
    _t789 = 1.0 if _tr(_t790) else 0.0
    if not _t789:
      _t789 = 1.0 if _tr((1.0 if abs(v_state - 3.0) < 0.00001 else 0.0)) else 0.0
    _t788 = 1.0 if _tr(_t789) else 0.0
    if not _t788:
      _t788 = 1.0 if _tr((1.0 if abs(v_state - 4.0) < 0.00001 else 0.0)) else 0.0
    _t787 = 1.0 if _tr(_t788) else 0.0
    if not _t787:
      _t787 = 1.0 if _tr((1.0 if abs(v_state - 5.0) < 0.00001 else 0.0)) else 0.0
    _t777 = 1.0 if _tr(_t787) else 0.0
  if _tr(_t777):
    _t792 = f_host_measure_len()
    L_m = _t792
    _t793 = (_mget(v_part_sm + L_idx) - L_m)
    _t794 = abs(_t793)
    if _tr((1.0 if _t794 < (L_m * 0.0002) else 0.0)):
      L_n = _div(v_length, L_m)
      if _tr((1.0 if L_n >= 0.999 else 0.0)):
        _t799 = v_length
        _t797 = (L_n + 0.5)
        _t798 = _floor(_t797)
        _t800 = (_t799 - (_t798 * L_m))
        _t801 = abs(_t800)
        if _tr((1.0 if _t801 < 8.0 else 0.0)):
          L_p = L_m
          L_ok = 1.0
          _t802 = L_ok
        else:
          _t802 = 0.0
        _t796 = _t802
      else:
        L_n = _div(L_m, v_length)
        _t805 = L_m
        _t803 = (L_n + 0.5)
        _t804 = _floor(_t803)
        _t806 = (_t805 - (_t804 * v_length))
        _t807 = abs(_t806)
        _t810 = _t807
        _t808 = (L_n + 0.5)
        _t809 = _floor(_t808)
        if _tr((1.0 if _t810 < (8.0 * _t809) else 0.0)):
          L_p = v_length
          L_ok = 1.0
          _t811 = L_ok
        else:
          _t811 = 0.0
        _t796 = _t811
      _t795 = _t796
    else:
      _t795 = 0.0
    _t791 = _t795
  else:
    _t791 = 0.0
  if _tr(L_ok):
    _t814 = (v_srate * 0.001)
    if _tr((1.0 if _gget(92.0) > 0.0 else 0.0)):
      _t813 = _gget(92.0)
    else:
      _t813 = 2.0
    _t815 = (_t814 * _t813)
    _t816 = max(8.0, _t815)
    L_thr = _t816
    _t817 = f_ref_host_phase()
    L_ph = _t817
    L_e = ((v_master_pos - _mget(v_part_sp + L_idx)) - L_ph)
    _t820 = L_p
    _t818 = (_div(L_e, L_p) + 0.5)
    _t819 = _floor(_t818)
    L_e = (L_e - (_t820 * _t819))
    _t821 = L_e
    _t822 = abs(_t821)
    if _tr((1.0 if _t822 > L_thr else 0.0)):
      v_rp_cnt = (v_rp_cnt + 1.0)
      if _tr((1.0 if v_rp_cnt >= 2.0 else 0.0)):
        _t825 = L_e
        _t826 = abs(_t825)
        if _tr((1.0 if _t826 > (v_srate * 0.05) else 0.0)):
          v_master_pos = (v_master_pos - L_e)
          _t830 = v_length
          _t828 = _div(v_master_pos, v_length)
          _t829 = _floor(_t828)
          v_master_pos = (v_master_pos - (_t830 * _t829))
          if _tr((1.0 if abs(v_active_part - 1.0) < 0.00001 else 0.0)):
            v_master_pos1 = v_master_pos
            _t831 = v_master_pos1
          else:
            if _tr((1.0 if abs(v_active_part - 2.0) < 0.00001 else 0.0)):
              v_master_pos2 = v_master_pos
              _t832 = v_master_pos2
            else:
              v_master_pos3 = v_master_pos
              _t832 = v_master_pos3
            _t831 = _t832
          v_sync_hard_resync = 1.0
          v_rp_pend = 0.0
          v_rp_cnt = 0.0
          _t827 = v_rp_cnt
        else:
          v_rp_pend = (-L_e)
          _t827 = v_rp_pend
        _t824 = _t827
      else:
        _t824 = 0.0
      _t823 = _t824
    else:
      v_rp_cnt = 0.0
      v_rp_pend = 0.0
      _t823 = v_rp_pend
    _t812 = _t823
  else:
    v_rp_cnt = 0.0
    v_rp_pend = 0.0
    _t812 = v_rp_pend
  return _t812

def f_finish_rec(L_new_state):
  global v_active_history_idx, v_active_part, v_base_backup_l, v_base_backup_r, v_base_len_part1, v_base_len_part2, v_base_len_part3, v_base_loop_length, v_buf_len, v_clk_cyc, v_delay_buf_l, v_delay_idx, v_delay_len, v_dirty_len, v_gmem, v_hist_len, v_instance_id, v_lat_samps, v_left_buf, v_len_part1, v_len_part2, v_len_part3, v_length, v_loop_start, v_loop_width, v_master_pos, v_master_pos1, v_master_pos2, v_master_pos3, v_mult_len, v_pos, v_rec_ref_kind, v_right_buf, v_smooth_start, v_smooth_width, v_state, v_sync_hard_resync, v_xfade_pos_active
  L_ms_off = 0.0
  L_k = 0.0
  _t833 = v_lat_samps
  _t834 = (v_pos * 0.25)
  _t835 = min(_t833, _t834)
  _t836 = _t835
  _t837 = _floor(_t836)
  L_k = _t837
  _t839 = 1.0 if _tr((1.0 if v_rec_ref_kind > 0.0 else 0.0)) else 0.0
  if _t839:
    _t839 = 1.0 if _tr((1.0 if L_k > 0.0 else 0.0)) else 0.0
  _t838 = 1.0 if _tr(_t839) else 0.0
  if _t838:
    _t838 = 1.0 if _tr((1.0 if (v_pos + L_k) <= v_buf_len else 0.0)) else 0.0
  if _tr(_t838):
    _t841 = (v_left_buf + v_pos)
    _t842 = v_left_buf
    _t843 = L_k
    _t844 = _memcpy(_t841, _t842, _t843)
    _t845 = (v_right_buf + v_pos)
    _t846 = v_right_buf
    _t847 = L_k
    _t848 = _memcpy(_t845, _t846, _t847)
    _t849 = v_left_buf
    _t850 = (v_left_buf + L_k)
    _t851 = v_pos
    _t852 = _memcpy(_t849, _t850, _t851)
    _t853 = v_right_buf
    _t854 = (v_right_buf + L_k)
    _t855 = v_pos
    _t856 = _memcpy(_t853, _t854, _t855)
    _t840 = _t856
  else:
    _t840 = 0.0
  _t857 = v_pos
  _t858 = max(_t857, 1.0)
  v_length = _t858
  v_base_loop_length = v_length
  v_mult_len = v_length
  _t859 = v_base_backup_l
  _t860 = v_left_buf
  _t861 = v_length
  _t862 = _memcpy(_t859, _t860, _t861)
  _t863 = v_base_backup_r
  _t864 = v_right_buf
  _t865 = v_length
  _t866 = _memcpy(_t863, _t864, _t865)
  if _tr((1.0 if abs(v_active_part - 1.0) < 0.00001 else 0.0)):
    v_len_part1 = v_length
    v_base_len_part1 = v_base_loop_length
    _t867 = v_base_len_part1
  else:
    _t867 = 0.0
  if _tr((1.0 if abs(v_active_part - 2.0) < 0.00001 else 0.0)):
    v_len_part2 = v_length
    v_base_len_part2 = v_base_loop_length
    _t868 = v_base_len_part2
  else:
    _t868 = 0.0
  if _tr((1.0 if abs(v_active_part - 3.0) < 0.00001 else 0.0)):
    v_len_part3 = v_length
    v_base_len_part3 = v_base_loop_length
    _t869 = v_base_len_part3
  else:
    _t869 = 0.0
  _t870 = _ix(v_hist_len + v_active_history_idx)
  _t871 = v_length
  _mset(_t870, _t871)
  _t872 = v_dirty_len
  _t873 = v_length
  _t874 = max(_t872, _t873)
  v_dirty_len = _t874
  v_loop_start = 0.0
  v_loop_width = v_length
  v_smooth_start = 0.0
  v_smooth_width = v_length
  v_pos = 0.0
  v_master_pos = 0.0
  v_clk_cyc = 0.0
  if _tr((1.0 if abs(v_active_part - 1.0) < 0.00001 else 0.0)):
    v_master_pos1 = 0.0
    _t875 = v_master_pos1
  else:
    if _tr((1.0 if abs(v_active_part - 2.0) < 0.00001 else 0.0)):
      v_master_pos2 = 0.0
      _t876 = v_master_pos2
    else:
      v_master_pos3 = 0.0
      _t876 = v_master_pos3
    _t875 = _t876
  v_xfade_pos_active = 0.0
  _t877 = v_delay_buf_l
  _t878 = (v_delay_len * 2.0)
  _t879 = _memset(_t877, 0.0, _t878)
  v_delay_idx = 0.0
  v_state = L_new_state
  _t880 = f_start_analysis()
  v_sync_hard_resync = 1.0
  _t881 = (v_active_part - 1.0)
  _t882 = f_sync_store(_t881)
  L_ms_off = ((v_active_part - 1.0) * 10.0)
  _t883 = 1.0 if _tr((1.0 if abs(_gget(L_ms_off) - 0.0) < 0.00001 else 0.0)) else 0.0
  if _t883:
    _t883 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
  if _tr(_t883):
    _t885 = _ix(L_ms_off)
    _t886 = 1.0
    _gset(_t885, _t886)
    _t887 = _ix((L_ms_off + 1.0))
    _t888 = v_instance_id
    _gset(_t887, _t888)
    _t889 = _ix((L_ms_off + 2.0))
    _t890 = v_base_loop_length
    _gset(_t889, _t890)
    _t891 = _ix((L_ms_off + 3.0))
    _t892 = v_master_pos
    _gset(_t891, _t892)
    _t884 = _t892
  else:
    _t884 = 0.0
  return _t884

def f_master_beat_len(L_mid):
  global v_gm_bpm, v_gmem, v_max_inst, v_srate
  L_i = 0.0
  L_b = 0.0
  L_p = 0.0
  L_bpm = 0.0
  L_r = 0.0
  L_r = 0.0
  L_i = 0.0
  for _t893 in range(max(0, int(v_max_inst))):
    L_b = (1000.0 + (L_i * 600.0))
    _t895 = 1.0 if _tr((1.0 if abs(L_r - 0.0) < 0.00001 else 0.0)) else 0.0
    if _t895:
      _t895 = 1.0 if _tr((1.0 if L_mid > 0.0 else 0.0)) else 0.0
    _t894 = 1.0 if _tr(_t895) else 0.0
    if _t894:
      _t896 = 1.0 if _tr((1.0 if abs(_gget(L_b) - L_mid) < 0.00001 else 0.0)) else 0.0
      if not _t896:
        _t896 = 1.0 if _tr((1.0 if abs(_gget((L_b + 1.0)) - L_mid) < 0.00001 else 0.0)) else 0.0
      _t894 = 1.0 if _tr(_t896) else 0.0
    if _tr(_t894):
      L_p = _gget((L_b + 42.0))
      if _tr((1.0 if L_p < 1.0 else 0.0)):
        L_p = 1.0
        _t898 = L_p
      else:
        _t898 = 0.0
      L_bpm = _gget(((L_b + ((L_p - 1.0) * 200.0)) + v_gm_bpm))
      if _tr((1.0 if L_bpm > 1.0 else 0.0)):
        L_r = _div((60.0 * v_srate), L_bpm)
        _t899 = L_r
      else:
        _t899 = 0.0
      _t897 = _t899
    else:
      _t897 = 0.0
    L_i = (L_i + 1.0)
  return L_r

def f_qs_setup():
  global v_active_part, v_gmem, v_instance_alias, v_instance_id, v_play_state, v_qs_frac, v_qs_mode, v_qs_unit, v_ts_num
  L_ms_off = 0.0
  L_locked = 0.0
  L_mid = 0.0
  L_is_self = 0.0
  L_mlen = 0.0
  L_hb = 0.0
  L_nb = 0.0
  L_sg = 0.0
  v_qs_mode = 0.0
  v_qs_frac = 0.0
  if _tr((1.0 if _gget(94.0) > 0.5 else 0.0)):
    L_ms_off = ((v_active_part - 1.0) * 10.0)
    L_locked = _gget(L_ms_off)
    L_mid = _gget((L_ms_off + 1.0))
    _t901 = 1.0 if _tr((1.0 if abs(L_locked - 1.0) < 0.00001 else 0.0)) else 0.0
    if _t901:
      _t902 = 1.0 if _tr((1.0 if abs(L_mid - v_instance_id) < 0.00001 else 0.0)) else 0.0
      if not _t902:
        _t902 = 1.0 if _tr((1.0 if abs(L_mid - v_instance_alias) < 0.00001 else 0.0)) else 0.0
      _t901 = 1.0 if _tr(_t902) else 0.0
    L_is_self = _t901
    _t903 = (_gget(99.0) + 0.5)
    _t904 = _floor(_t903)
    _t905 = _t904
    _t906 = min(4.0, _t905)
    _t907 = _t906
    _t908 = max(0.0, _t907)
    L_sg = _t908
    v_qs_frac = (1.0 if abs(L_sg - 0.0) < 0.00001 else 0.0)
    _t909 = 1.0 if _tr((1.0 if abs(L_locked - 2.0) < 0.00001 else 0.0)) else 0.0
    if _t909:
      _t909 = 1.0 if _tr(float(int(v_play_state) & int(1.0))) else 0.0
    if _tr(_t909):
      v_qs_mode = 1.0
      if _tr((1.0 if abs(L_sg - 0.0) < 0.00001 else 0.0)):
        if _tr((1.0 if v_ts_num > 0.0 else 0.0)):
          _t912 = v_ts_num
        else:
          _t912 = 4.0
        _t911 = _t912
      else:
        _t911 = _div(1.0, L_sg)
      v_qs_unit = _t911
      _t910 = v_qs_unit
    else:
      _t914 = 1.0 if _tr((1.0 if abs(L_locked - 1.0) < 0.00001 else 0.0)) else 0.0
      if _t914:
        _t914 = 1.0 if _tr((0.0 if _tr(L_is_self) else 1.0)) else 0.0
      _t913 = 1.0 if _tr(_t914) else 0.0
      if _t913:
        _t913 = 1.0 if _tr((1.0 if _gget((L_ms_off + 2.0)) > 0.0 else 0.0)) else 0.0
      if _tr(_t913):
        L_mlen = _gget((L_ms_off + 2.0))
        v_qs_unit = L_mlen
        if _tr((1.0 if L_sg > 0.0 else 0.0)):
          _t917 = L_mid
          _t918 = f_master_beat_len(_t917)
          L_hb = _t918
          if _tr((1.0 if L_hb > 0.0 else 0.0)):
            _t919 = _div(L_mlen, L_hb)
          else:
            _t919 = 0.0
          L_nb = _t919
          _t920 = 1.0 if _tr((1.0 if L_nb >= 1.0 else 0.0)) else 0.0
          if _t920:
            _t923 = L_nb
            _t921 = (L_nb + 0.5)
            _t922 = _floor(_t921)
            _t924 = (_t923 - _t922)
            _t925 = abs(_t924)
            _t920 = 1.0 if _tr((1.0 if _t925 < 0.05 else 0.0)) else 0.0
          if _tr(_t920):
            v_qs_unit = _div(L_hb, L_sg)
            _t926 = v_qs_unit
          else:
            v_qs_frac = 1.0
            _t926 = v_qs_frac
          _t916 = _t926
        else:
          _t916 = 0.0
        v_qs_mode = 2.0
        _t915 = v_qs_mode
      else:
        _t915 = 0.0
      _t910 = _t915
    _t900 = _t910
  else:
    _t900 = 0.0
  return (1.0 if v_qs_mode > 0.0 else 0.0)

def f_qs_check():
  global v_active_part, v_gmem, v_play_state, v_qs_b0, v_qs_frac, v_qs_hit, v_qs_i, v_qs_mode, v_qs_prev, v_qs_unit, v_srate, v_tempo
  L_ph = 0.0
  if _tr((1.0 if abs(v_qs_mode - 1.0) < 0.00001 else 0.0)):
    if _tr((1.0 if abs(float(int(v_play_state) & int(1.0)) - 0.0) < 0.00001 else 0.0)):
      v_qs_hit = 1.0
      _t928 = v_qs_hit
    else:
      L_ph = _div((v_qs_b0 + _div((v_qs_i * v_tempo), (60.0 * v_srate))), v_qs_unit)
      _t929 = L_ph
      _t930 = _floor(_t929)
      L_ph = (L_ph - _t930)
      _t931 = 1.0 if _tr((1.0 if v_qs_prev >= 0.0 else 0.0)) else 0.0
      if _t931:
        _t931 = 1.0 if _tr((1.0 if L_ph < v_qs_prev else 0.0)) else 0.0
      if _tr(_t931):
        v_qs_hit = 1.0
        _t932 = v_qs_hit
      else:
        _t932 = 0.0
      _t934 = 1.0 if _tr(v_qs_frac) else 0.0
      if _t934:
        _t934 = 1.0 if _tr((1.0 if v_qs_prev >= 0.0 else 0.0)) else 0.0
      _t933 = 1.0 if _tr(_t934) else 0.0
      if _t933:
        _t937 = 1.0 if _tr((1.0 if v_qs_prev < 0.125 else 0.0)) else 0.0
        if _t937:
          _t937 = 1.0 if _tr((1.0 if L_ph >= 0.125 else 0.0)) else 0.0
        _t936 = 1.0 if _tr(_t937) else 0.0
        if not _t936:
          _t938 = 1.0 if _tr((1.0 if v_qs_prev < 0.25 else 0.0)) else 0.0
          if _t938:
            _t938 = 1.0 if _tr((1.0 if L_ph >= 0.25 else 0.0)) else 0.0
          _t936 = 1.0 if _tr(_t938) else 0.0
        _t935 = 1.0 if _tr(_t936) else 0.0
        if not _t935:
          _t939 = 1.0 if _tr((1.0 if v_qs_prev < 0.5 else 0.0)) else 0.0
          if _t939:
            _t939 = 1.0 if _tr((1.0 if L_ph >= 0.5 else 0.0)) else 0.0
          _t935 = 1.0 if _tr(_t939) else 0.0
        _t933 = 1.0 if _tr(_t935) else 0.0
      if _tr(_t933):
        v_qs_hit = 1.0
        _t940 = v_qs_hit
      else:
        _t940 = 0.0
      v_qs_prev = L_ph
      _t928 = v_qs_prev
    _t927 = _t928
  else:
    L_ph = _div(_gget((((v_active_part - 1.0) * 10.0) + 3.0)), v_qs_unit)
    _t941 = L_ph
    _t942 = _floor(_t941)
    L_ph = (L_ph - _t942)
    _t943 = 1.0 if _tr((1.0 if v_qs_prev >= 0.0 else 0.0)) else 0.0
    if _t943:
      _t943 = 1.0 if _tr((1.0 if L_ph < v_qs_prev else 0.0)) else 0.0
    if _tr(_t943):
      v_qs_hit = 1.0
      _t944 = v_qs_hit
    else:
      _t944 = 0.0
    _t946 = 1.0 if _tr(v_qs_frac) else 0.0
    if _t946:
      _t946 = 1.0 if _tr((1.0 if v_qs_prev >= 0.0 else 0.0)) else 0.0
    _t945 = 1.0 if _tr(_t946) else 0.0
    if _t945:
      _t949 = 1.0 if _tr((1.0 if v_qs_prev < 0.125 else 0.0)) else 0.0
      if _t949:
        _t949 = 1.0 if _tr((1.0 if L_ph >= 0.125 else 0.0)) else 0.0
      _t948 = 1.0 if _tr(_t949) else 0.0
      if not _t948:
        _t950 = 1.0 if _tr((1.0 if v_qs_prev < 0.25 else 0.0)) else 0.0
        if _t950:
          _t950 = 1.0 if _tr((1.0 if L_ph >= 0.25 else 0.0)) else 0.0
        _t948 = 1.0 if _tr(_t950) else 0.0
      _t947 = 1.0 if _tr(_t948) else 0.0
      if not _t947:
        _t951 = 1.0 if _tr((1.0 if v_qs_prev < 0.5 else 0.0)) else 0.0
        if _t951:
          _t951 = 1.0 if _tr((1.0 if L_ph >= 0.5 else 0.0)) else 0.0
        _t947 = 1.0 if _tr(_t951) else 0.0
      _t945 = 1.0 if _tr(_t947) else 0.0
    if _tr(_t945):
      v_qs_hit = 1.0
      _t952 = v_qs_hit
    else:
      _t952 = 0.0
    v_qs_prev = L_ph
    _t927 = v_qs_prev
  return _t927

def f_try_finish_rec(L_target, L_from_auto):
  global v_active_part, v_co_rec, v_gmem, v_instance_alias, v_instance_id, v_master_pos, v_master_pos1, v_master_pos2, v_master_pos3, v_pending_next_state, v_pingpong_on, v_pos, v_rec_ref_id, v_rec_ref_kind, v_rec_ref_len, v_rec_ref_ph, v_rec_stop_lag, v_rev_on, v_srate, v_state, v_target_sync_len, v_tempo
  L_ms_off = 0.0
  L_locked = 0.0
  L_mid = 0.0
  L_is_self = 0.0
  L_is_host = 0.0
  L_master_len = 0.0
  L_has_ref = 0.0
  L_k = 0.0
  L_sg = 0.0
  L_hb = 0.0
  L_nb = 0.0
  L_unit = 0.0
  L_ms_off = ((v_active_part - 1.0) * 10.0)
  L_locked = _gget(L_ms_off)
  L_mid = _gget((L_ms_off + 1.0))
  _t953 = 1.0 if _tr((1.0 if abs(L_locked - 1.0) < 0.00001 else 0.0)) else 0.0
  if _t953:
    _t954 = 1.0 if _tr((1.0 if abs(L_mid - v_instance_id) < 0.00001 else 0.0)) else 0.0
    if not _t954:
      _t954 = 1.0 if _tr((1.0 if abs(L_mid - v_instance_alias) < 0.00001 else 0.0)) else 0.0
    _t953 = 1.0 if _tr(_t954) else 0.0
  L_is_self = _t953
  L_is_host = (1.0 if abs(L_locked - 2.0) < 0.00001 else 0.0)
  if _tr(L_is_host):
    _t956 = f_host_measure_len()
    _t955 = _t956
  else:
    _t958 = 1.0 if _tr((1.0 if abs(L_locked - 1.0) < 0.00001 else 0.0)) else 0.0
    if _t958:
      _t958 = 1.0 if _tr((0.0 if _tr(L_is_self) else 1.0)) else 0.0
    _t957 = 1.0 if _tr(_t958) else 0.0
    if _t957:
      _t957 = 1.0 if _tr((1.0 if _gget((L_ms_off + 2.0)) > 0.0 else 0.0)) else 0.0
    if _tr(_t957):
      _t959 = _gget((L_ms_off + 2.0))
    else:
      _t959 = 0.0
    _t955 = _t959
  L_master_len = _t955
  L_has_ref = (1.0 if L_master_len > 0.0 else 0.0)
  _t963 = 1.0 if _tr((1.0 if abs(v_rec_ref_kind - 0.0) < 0.00001 else 0.0)) else 0.0
  if _t963:
    _t963 = 1.0 if _tr((1.0 if abs(L_locked - 1.0) < 0.00001 else 0.0)) else 0.0
  _t962 = 1.0 if _tr(_t963) else 0.0
  if _t962:
    _t962 = 1.0 if _tr((0.0 if _tr(L_is_self) else 1.0)) else 0.0
  _t961 = 1.0 if _tr(_t962) else 0.0
  if _t961:
    _t961 = 1.0 if _tr((1.0 if L_master_len > 0.0 else 0.0)) else 0.0
  _t960 = 1.0 if _tr(_t961) else 0.0
  if _t960:
    _t964 = (v_pos - L_master_len)
    _t965 = abs(_t964)
    _t960 = 1.0 if _tr((1.0 if _t965 < (v_srate * 0.3) else 0.0)) else 0.0
  if _tr(_t960):
    _t967 = (v_active_part - 1.0)
    _t968 = f_sy_master_blk(_t967)
    L_k = _t968
    v_rec_ref_kind = 1.0
    _t969 = 1.0 if _tr((1.0 if L_k >= 0.0 else 0.0)) else 0.0
    if _t969:
      _t969 = 1.0 if _tr((1.0 if _gget((L_k + 183.0)) > 0.0 else 0.0)) else 0.0
    if _tr(_t969):
      _t970 = _gget((L_k + 183.0))
    else:
      _t970 = L_mid
    v_rec_ref_id = _t970
    v_rec_ref_len = L_master_len
    v_rec_ref_ph = 0.0
    L_has_ref = 1.0
    L_sg = 0.0
    L_unit = 0.0
    v_target_sync_len = L_master_len
    v_state = 8.0
    v_pending_next_state = L_target
    v_rec_stop_lag = 0.0
    v_co_rec = 1.0
    _t966 = v_co_rec
  else:
    _t971 = (_gget(99.0) + 0.5)
    _t972 = _floor(_t971)
    _t973 = _t972
    _t974 = min(4.0, _t973)
    _t975 = _t974
    _t976 = max(0.0, _t975)
    L_sg = _t976
    L_unit = 0.0
    _t977 = 1.0 if _tr(L_has_ref) else 0.0
    if _t977:
      _t977 = 1.0 if _tr((1.0 if L_sg > 0.0 else 0.0)) else 0.0
    if _tr(_t977):
      if _tr(L_is_host):
        _t982 = (60.0 * v_srate)
        _t980 = v_tempo
        _t981 = max(_t980, 20.0)
        _t979 = _div(_t982, _t981)
      else:
        _t983 = L_mid
        _t984 = f_master_beat_len(_t983)
        _t979 = _t984
      L_hb = _t979
      if _tr((1.0 if L_hb > 0.0 else 0.0)):
        _t985 = _div(L_master_len, L_hb)
      else:
        _t985 = 0.0
      L_nb = _t985
      _t986 = 1.0 if _tr((1.0 if L_nb >= 1.0 else 0.0)) else 0.0
      if _t986:
        _t989 = L_nb
        _t987 = (L_nb + 0.5)
        _t988 = _floor(_t987)
        _t990 = (_t989 - _t988)
        _t991 = abs(_t990)
        _t986 = 1.0 if _tr((1.0 if _t991 < 0.05 else 0.0)) else 0.0
      if _tr(_t986):
        L_unit = _div(L_hb, L_sg)
        _t992 = L_unit
      else:
        _t992 = 0.0
      _t978 = _t992
    else:
      _t978 = 0.0
    if _tr(L_has_ref):
      if _tr((1.0 if L_unit > 0.0 else 0.0)):
        if _tr(L_from_auto):
          _t996 = (_div(v_pos, L_unit) + 0.5)
          _t997 = _floor(_t996)
          _t998 = _t997
          _t999 = max(1.0, _t998)
          _t995 = _t999
        else:
          _t1000 = (_div(v_pos, L_unit) - 1e-06)
          _t1001 = _ceil(_t1000)
          _t1002 = _t1001
          _t1003 = max(1.0, _t1002)
          _t995 = _t1003
        L_k = _t995
        v_target_sync_len = (L_k * L_unit)
        _t994 = v_target_sync_len
      else:
        if _tr(L_from_auto):
          _t1005 = (_div(v_pos, L_master_len) + 0.5)
          _t1006 = _floor(_t1005)
          _t1007 = _t1006
          _t1008 = max(1.0, _t1007)
          L_k = _t1008
          v_target_sync_len = (L_k * L_master_len)
          _t1004 = v_target_sync_len
        else:
          _t1009 = v_pos
          _t1010 = L_master_len
          _t1011 = f_calc_sync_len(_t1009, _t1010)
          v_target_sync_len = _t1011
          _t1004 = v_target_sync_len
        _t994 = _t1004
      v_state = 8.0
      v_pending_next_state = L_target
      _t993 = v_pending_next_state
    else:
      L_k = v_rec_stop_lag
      v_rec_stop_lag = 0.0
      _t1014 = 1.0 if _tr((1.0 if L_k > 0.0 else 0.0)) else 0.0
      if _t1014:
        _t1014 = 1.0 if _tr((0.0 if _tr(v_rev_on) else 1.0)) else 0.0
      _t1013 = 1.0 if _tr(_t1014) else 0.0
      if _t1013:
        _t1013 = 1.0 if _tr((0.0 if _tr(v_pingpong_on) else 1.0)) else 0.0
      _t1012 = 1.0 if _tr(_t1013) else 0.0
      if _t1012:
        _t1018 = (v_pos - L_k)
        _t1015 = (v_srate * 0.1)
        _t1016 = (L_k * 2.0)
        _t1017 = max(_t1015, _t1016)
        _t1012 = 1.0 if _tr((1.0 if _t1018 > _t1017 else 0.0)) else 0.0
      if _tr(_t1012):
        v_pos = (v_pos - L_k)
        _t1019 = v_pos
      else:
        L_k = 0.0
        _t1019 = L_k
      _t1020 = L_target
      _t1021 = f_finish_rec(_t1020)
      if _tr((1.0 if L_k > 0.0 else 0.0)):
        _t1023 = L_k
        _t1024 = _floor(_t1023)
        L_k = _t1024
        v_pos = L_k
        v_master_pos = L_k
        if _tr((1.0 if abs(v_active_part - 1.0) < 0.00001 else 0.0)):
          v_master_pos1 = L_k
          _t1025 = v_master_pos1
        else:
          if _tr((1.0 if abs(v_active_part - 2.0) < 0.00001 else 0.0)):
            v_master_pos2 = L_k
            _t1026 = v_master_pos2
          else:
            v_master_pos3 = L_k
            _t1026 = v_master_pos3
          _t1025 = _t1026
        _t1022 = _t1025
      else:
        _t1022 = 0.0
      _t993 = _t1022
    _t966 = _t993
  return _t966

def f_switch_part(L_new_part):
  global v_active_part, v_auto_on, v_base_len_part1, v_base_len_part2, v_base_len_part3, v_base_loop_length, v_buf_len, v_buf_part1_l, v_buf_part1_r, v_buf_part2_l, v_buf_part2_r, v_buf_part3_l, v_buf_part3_r, v_clk_cyc, v_clk_cyc1, v_clk_cyc2, v_clk_cyc3, v_clk_len_ref, v_cloud_on, v_dirty_len, v_frz_copying, v_frz_prev, v_frz_ready, v_hist_len, v_hist_redo, v_hist_undo, v_history_count, v_history_head, v_last_state_target, v_left_buf, v_len_part1, v_len_part2, v_len_part3, v_length, v_link_on, v_loop_start, v_loop_width, v_master_pos, v_master_pos1, v_master_pos2, v_master_pos3, v_part_cloud_on, v_part_link_on, v_part_pingpong, v_part_pitch, v_part_play_mode, v_part_rev, v_part_speed, v_pingpong_on, v_pitch, v_play_mode, v_pos, v_rd_valid, v_rev_on, v_right_buf, v_rp_tail_on, v_smooth_start, v_smooth_width, v_speed, v_state, v_state_target, v_sync_hard_resync, v_warp_on, v_wp_busy, v_wp_live, v_wp_phase, v_wp_scan, v_xf_on, v_xfade_pos_active
  L_target_len = 0.0
  L_target_base_len = 0.0
  L_idx_old = 0.0
  L_idx_new = 0.0
  v_xf_on = 0.0
  v_rd_valid = 0.0
  v_rp_tail_on = 0.0
  v_frz_ready = 0.0
  v_frz_copying = 0.0
  v_frz_prev = (-1.0)
  v_wp_busy = 0.0
  v_wp_phase = 0.0
  v_wp_live = 0.0
  v_wp_scan = 0.0
  v_warp_on = 0.0
  v_warp_on = 0.0
  _t1027 = f_dub_flush()
  if _tr((1.0 if abs(v_state - 1.0) < 0.00001 else 0.0)):
    _t1029 = f_try_finish_rec(2.0, 0.0)
    _t1028 = _t1029
  else:
    _t1028 = 0.0
  L_idx_old = (v_active_part - 1.0)
  _t1030 = _ix(v_part_speed + L_idx_old)
  _t1031 = v_speed
  _mset(_t1030, _t1031)
  _t1032 = _ix(v_part_pitch + L_idx_old)
  _t1033 = v_pitch
  _mset(_t1032, _t1033)
  _t1034 = _ix(v_part_rev + L_idx_old)
  _t1035 = v_rev_on
  _mset(_t1034, _t1035)
  _t1036 = _ix(v_part_pingpong + L_idx_old)
  _t1037 = v_pingpong_on
  _mset(_t1036, _t1037)
  _t1038 = _ix(v_part_play_mode + L_idx_old)
  _t1039 = v_play_mode
  _mset(_t1038, _t1039)
  _t1040 = _ix(v_part_cloud_on + L_idx_old)
  _t1041 = v_cloud_on
  _mset(_t1040, _t1041)
  _t1042 = _ix(v_part_link_on + L_idx_old)
  _t1043 = v_link_on
  _mset(_t1042, _t1043)
  if _tr((1.0 if abs(v_active_part - 1.0) < 0.00001 else 0.0)):
    v_master_pos1 = v_master_pos
    v_clk_cyc1 = v_clk_cyc
    v_len_part1 = v_length
    v_base_len_part1 = v_base_loop_length
    if _tr((0.0 if abs(v_left_buf - v_buf_part1_l) < 0.00001 else 1.0)):
      _t1046 = v_buf_part1_l
      _t1047 = v_left_buf
      _t1048 = v_length
      _t1049 = _memcpy(_t1046, _t1047, _t1048)
      _t1050 = v_buf_part1_r
      _t1051 = v_right_buf
      _t1052 = v_length
      _t1053 = _memcpy(_t1050, _t1051, _t1052)
      _t1045 = _t1053
    else:
      _t1045 = 0.0
    _t1044 = _t1045
  else:
    if _tr((1.0 if abs(v_active_part - 2.0) < 0.00001 else 0.0)):
      v_master_pos2 = v_master_pos
      v_clk_cyc2 = v_clk_cyc
      v_len_part2 = v_length
      v_base_len_part2 = v_base_loop_length
      if _tr((0.0 if abs(v_left_buf - v_buf_part2_l) < 0.00001 else 1.0)):
        _t1056 = v_buf_part2_l
        _t1057 = v_left_buf
        _t1058 = v_length
        _t1059 = _memcpy(_t1056, _t1057, _t1058)
        _t1060 = v_buf_part2_r
        _t1061 = v_right_buf
        _t1062 = v_length
        _t1063 = _memcpy(_t1060, _t1061, _t1062)
        _t1055 = _t1063
      else:
        _t1055 = 0.0
      _t1054 = _t1055
    else:
      v_master_pos3 = v_master_pos
      v_clk_cyc3 = v_clk_cyc
      v_len_part3 = v_length
      v_base_len_part3 = v_base_loop_length
      if _tr((0.0 if abs(v_left_buf - v_buf_part3_l) < 0.00001 else 1.0)):
        _t1065 = v_buf_part3_l
        _t1066 = v_left_buf
        _t1067 = v_length
        _t1068 = _memcpy(_t1065, _t1066, _t1067)
        _t1069 = v_buf_part3_r
        _t1070 = v_right_buf
        _t1071 = v_length
        _t1072 = _memcpy(_t1069, _t1070, _t1071)
        _t1064 = _t1072
      else:
        _t1064 = 0.0
      _t1054 = _t1064
    _t1044 = _t1054
  v_active_part = L_new_part
  v_history_head = 0.0
  v_history_count = 1.0
  v_hist_undo = 0.0
  v_hist_redo = 0.0
  v_dirty_len = 0.0
  _t1073 = f_switch_history_slot(0.0)
  if _tr((1.0 if abs(L_new_part - 1.0) < 0.00001 else 0.0)):
    L_target_len = v_len_part1
    L_target_base_len = v_base_len_part1
    _t1074 = L_target_base_len
  else:
    if _tr((1.0 if abs(L_new_part - 2.0) < 0.00001 else 0.0)):
      L_target_len = v_len_part2
      L_target_base_len = v_base_len_part2
      _t1075 = L_target_base_len
    else:
      L_target_len = v_len_part3
      L_target_base_len = v_base_len_part3
      _t1075 = L_target_base_len
    _t1074 = _t1075
  v_length = L_target_len
  v_base_loop_length = L_target_base_len
  _t1076 = _ix(v_hist_len + 0.0)
  _t1077 = v_length
  _mset(_t1076, _t1077)
  L_idx_new = (L_new_part - 1.0)
  v_speed = _mget(v_part_speed + L_idx_new)
  v_speed = v_speed
  v_pitch = _mget(v_part_pitch + L_idx_new)
  v_pitch = v_pitch
  v_rev_on = _mget(v_part_rev + L_idx_new)
  v_rev_on = v_rev_on
  v_pingpong_on = _mget(v_part_pingpong + L_idx_new)
  v_pingpong_on = v_pingpong_on
  v_play_mode = _mget(v_part_play_mode + L_idx_new)
  v_play_mode = v_play_mode
  v_cloud_on = _mget(v_part_cloud_on + L_idx_new)
  v_cloud_on = v_cloud_on
  v_link_on = _mget(v_part_link_on + L_idx_new)
  v_link_on = v_link_on
  v_loop_start = 0.0
  if _tr((1.0 if v_length > 0.0 else 0.0)):
    _t1078 = v_length
  else:
    _t1078 = 0.0
  v_loop_width = _t1078
  v_smooth_start = 0.0
  v_smooth_width = v_loop_width
  v_pos = 0.0
  v_master_pos = 0.0
  if _tr((1.0 if abs(L_new_part - 1.0) < 0.00001 else 0.0)):
    v_master_pos1 = 0.0
    _t1079 = v_master_pos1
  else:
    if _tr((1.0 if abs(L_new_part - 2.0) < 0.00001 else 0.0)):
      v_master_pos2 = 0.0
      _t1080 = v_master_pos2
    else:
      v_master_pos3 = 0.0
      _t1080 = v_master_pos3
    _t1079 = _t1080
  v_clk_len_ref = v_length
  v_xfade_pos_active = 0.0
  v_sync_hard_resync = 1.0
  if _tr((1.0 if v_length <= 0.0 else 0.0)):
    v_dirty_len = v_buf_len
    v_state = 0.0
    if _tr(v_auto_on):
      _t1082 = 7.0
    else:
      _t1082 = 1.0
    v_state_target = _t1082
    v_master_pos = 0.0
    v_clk_cyc = 0.0
    _t1081 = v_clk_cyc
  else:
    v_state = 2.0
    v_state_target = 3.0
    _t1083 = f_start_analysis()
    _t1081 = _t1083
  v_last_state_target = (-1.0)
  return v_last_state_target

def f_push_new_history_state():
  global v_active_history_idx, v_an_after_wp, v_analysing, v_dirty_len, v_hist_len, v_hist_redo, v_hist_undo, v_history_count, v_history_head, v_left_buf, v_length, v_max_history, v_right_buf, v_single_buf_len, v_warp_on, v_wp_busy, v_wp_len, v_wp_live, v_wp_phase, v_wp_scan, v_wp_sig, v_wp_sig_job, v_wp_tl, v_wp_trr, v_wp_wl, v_wp_wsl
  L_src_l = 0.0
  L_src_r = 0.0
  L_new_idx = 0.0
  if _tr((1.0 if abs(v_wp_phase - 7.0) < 0.00001 else 0.0)):
    _t1085 = v_wp_wl
    _t1086 = v_wp_tl
    _t1087 = v_wp_len
    _t1088 = _memcpy(_t1085, _t1086, _t1087)
    _t1089 = (v_wp_wl + v_single_buf_len)
    _t1090 = v_wp_trr
    _t1091 = v_wp_len
    _t1092 = _memcpy(_t1089, _t1090, _t1091)
    _t1093 = v_wp_wsl
    _t1094 = f_switch_history_slot(_t1093)
    v_wp_busy = 0.0
    v_wp_phase = 0.0
    v_wp_sig = v_wp_sig_job
    _t1084 = v_wp_sig
  else:
    _t1084 = 0.0
  if _tr(v_wp_busy):
    v_wp_busy = 0.0
    v_wp_phase = 0.0
    if _tr(v_wp_scan):
      v_wp_scan = 0.0
      v_analysing = 0.0
      v_an_after_wp = 1.0
      _t1096 = v_an_after_wp
    else:
      _t1096 = 0.0
    _t1095 = _t1096
  else:
    _t1095 = 0.0
  if _tr(v_wp_live):
    v_wp_live = 0.0
    v_warp_on = 0.0
    v_warp_on = 0.0
    _t1097 = v_warp_on
  else:
    _t1097 = 0.0
  L_new_idx = _mod((v_active_history_idx + 1.0), v_max_history)
  L_src_l = v_left_buf
  L_src_r = v_right_buf
  _t1098 = L_new_idx
  _t1099 = f_switch_history_slot(_t1098)
  v_history_head = L_new_idx
  _t1100 = v_left_buf
  _t1101 = L_src_l
  _t1102 = v_length
  _t1103 = _memcpy(_t1100, _t1101, _t1102)
  _t1104 = v_right_buf
  _t1105 = L_src_r
  _t1106 = v_length
  _t1107 = _memcpy(_t1104, _t1105, _t1106)
  _t1108 = _ix(v_hist_len + L_new_idx)
  _t1109 = v_length
  _mset(_t1108, _t1109)
  _t1110 = v_dirty_len
  _t1111 = v_length
  _t1112 = max(_t1110, _t1111)
  v_dirty_len = _t1112
  _t1113 = (v_hist_undo + 1.0)
  _t1114 = (v_max_history - 1.0)
  _t1115 = min(_t1113, _t1114)
  v_hist_undo = _t1115
  v_hist_redo = 0.0
  v_history_count = (v_hist_undo + 1.0)
  return v_history_count

def f_sync_length_from_history():
  global v_active_history_idx, v_hist_len, v_length, v_loop_start, v_loop_width, v_master_pos, v_pos, v_smooth_start, v_smooth_width, v_xfade_pos_active
  L_nl = 0.0
  L_nl = _mget(v_hist_len + v_active_history_idx)
  _t1116 = 1.0 if _tr((1.0 if L_nl > 0.0 else 0.0)) else 0.0
  if _t1116:
    _t1116 = 1.0 if _tr((0.0 if abs(L_nl - v_length) < 0.00001 else 1.0)) else 0.0
  if _tr(_t1116):
    v_length = L_nl
    v_loop_start = 0.0
    v_loop_width = v_length
    v_smooth_start = 0.0
    v_smooth_width = v_length
    if _tr((1.0 if v_pos >= v_length else 0.0)):
      v_pos = 0.0
      _t1118 = v_pos
    else:
      _t1118 = 0.0
    _t1119 = v_master_pos
    _t1120 = v_length
    _t1121 = min(_t1119, _t1120)
    v_master_pos = _t1121
    v_xfade_pos_active = 0.0
    _t1122 = f_start_analysis()
    _t1117 = _t1122
  else:
    _t1117 = 0.0
  return _t1117

def f_undo_state():
  global v_active_history_idx, v_an_after_wp, v_analysing, v_hist_redo, v_hist_undo, v_max_history, v_rp_tail_on, v_single_buf_len, v_sync_hard_resync, v_wp_busy, v_wp_len, v_wp_phase, v_wp_scan, v_wp_sig, v_wp_sig_job, v_wp_tl, v_wp_trr, v_wp_wl, v_wp_wsl
  if _tr((1.0 if abs(v_wp_phase - 7.0) < 0.00001 else 0.0)):
    _t1124 = v_wp_wl
    _t1125 = v_wp_tl
    _t1126 = v_wp_len
    _t1127 = _memcpy(_t1124, _t1125, _t1126)
    _t1128 = (v_wp_wl + v_single_buf_len)
    _t1129 = v_wp_trr
    _t1130 = v_wp_len
    _t1131 = _memcpy(_t1128, _t1129, _t1130)
    _t1132 = v_wp_wsl
    _t1133 = f_switch_history_slot(_t1132)
    v_wp_busy = 0.0
    v_wp_phase = 0.0
    v_wp_sig = v_wp_sig_job
    _t1123 = v_wp_sig
  else:
    _t1123 = 0.0
  if _tr(v_wp_busy):
    v_wp_busy = 0.0
    v_wp_phase = 0.0
    if _tr(v_wp_scan):
      v_wp_scan = 0.0
      v_analysing = 0.0
      v_an_after_wp = 1.0
      _t1135 = v_an_after_wp
    else:
      _t1135 = 0.0
    _t1134 = _t1135
  else:
    _t1134 = 0.0
  v_rp_tail_on = 0.0
  _t1136 = f_dub_flush()
  if _tr((1.0 if v_hist_undo > 0.0 else 0.0)):
    v_active_history_idx = _mod(((v_active_history_idx - 1.0) + v_max_history), v_max_history)
    _t1138 = v_active_history_idx
    _t1139 = f_switch_history_slot(_t1138)
    v_hist_undo = (v_hist_undo - 1.0)
    v_hist_redo = (v_hist_redo + 1.0)
    _t1140 = f_sync_length_from_history()
    v_sync_hard_resync = 1.0
    _t1137 = v_sync_hard_resync
  else:
    _t1137 = 0.0
  return _t1137

def f_redo_state():
  global v_active_history_idx, v_an_after_wp, v_analysing, v_hist_redo, v_hist_undo, v_max_history, v_rp_tail_on, v_single_buf_len, v_sync_hard_resync, v_wp_busy, v_wp_len, v_wp_phase, v_wp_scan, v_wp_sig, v_wp_sig_job, v_wp_tl, v_wp_trr, v_wp_wl, v_wp_wsl
  if _tr((1.0 if abs(v_wp_phase - 7.0) < 0.00001 else 0.0)):
    _t1142 = v_wp_wl
    _t1143 = v_wp_tl
    _t1144 = v_wp_len
    _t1145 = _memcpy(_t1142, _t1143, _t1144)
    _t1146 = (v_wp_wl + v_single_buf_len)
    _t1147 = v_wp_trr
    _t1148 = v_wp_len
    _t1149 = _memcpy(_t1146, _t1147, _t1148)
    _t1150 = v_wp_wsl
    _t1151 = f_switch_history_slot(_t1150)
    v_wp_busy = 0.0
    v_wp_phase = 0.0
    v_wp_sig = v_wp_sig_job
    _t1141 = v_wp_sig
  else:
    _t1141 = 0.0
  if _tr(v_wp_busy):
    v_wp_busy = 0.0
    v_wp_phase = 0.0
    if _tr(v_wp_scan):
      v_wp_scan = 0.0
      v_analysing = 0.0
      v_an_after_wp = 1.0
      _t1153 = v_an_after_wp
    else:
      _t1153 = 0.0
    _t1152 = _t1153
  else:
    _t1152 = 0.0
  v_rp_tail_on = 0.0
  _t1154 = f_dub_flush()
  if _tr((1.0 if v_hist_redo > 0.0 else 0.0)):
    v_active_history_idx = _mod((v_active_history_idx + 1.0), v_max_history)
    _t1156 = v_active_history_idx
    _t1157 = f_switch_history_slot(_t1156)
    v_hist_redo = (v_hist_redo - 1.0)
    v_hist_undo = (v_hist_undo + 1.0)
    _t1158 = f_sync_length_from_history()
    v_sync_hard_resync = 1.0
    _t1155 = v_sync_hard_resync
  else:
    _t1155 = 0.0
  return _t1155

def f_get_slicer_len():
  global v_slicer_mode, v_slicer_steps, v_trans_count
  if _tr((1.0 if abs(v_slicer_mode - 5.0) < 0.00001 else 0.0)):
    _t1160 = v_trans_count
    _t1161 = max(1.0, _t1160)
    _t1159 = _t1161
  else:
    if _tr((1.0 if abs(v_slicer_mode - 0.0) < 0.00001 else 0.0)):
      _t1162 = 16.0
    else:
      _t1163 = (v_slicer_steps + 0.5)
      _t1164 = _floor(_t1163)
      _t1165 = _t1164
      _t1166 = min(32.0, _t1165)
      _t1167 = _t1166
      _t1168 = max(1.0, _t1167)
      _t1162 = _t1168
    _t1159 = _t1162
  return _t1159

def f_update_slicer_pitches(L_step_len):
  global v_slice_pitch_mem, v_slicer_pitch_spread
  L_i = 0.0
  L_ratio_p = 0.0
  L_impact_pct = 0.0
  L_ext_pct = 0.0
  L_idx_norm = 0.0
  L_active_double = 0.0
  L_i = 0.0
  for _t1169 in range(max(0, int(L_step_len))):
    L_ratio_p = (v_slicer_pitch_spread * 0.01)
    if _tr((1.0 if L_ratio_p <= 0.0001 else 0.0)):
      _t1171 = _ix(v_slice_pitch_mem + L_i)
      _t1172 = 0.0
      _mset(_t1171, _t1172)
      _t1170 = _t1172
    else:
      if _tr((1.0 if L_ratio_p <= 0.5 else 0.0)):
        L_impact_pct = (L_ratio_p * 2.0)
        if _tr((1.0 if _div(L_i, L_step_len) < L_impact_pct else 0.0)):
          _t1175 = _ix(v_slice_pitch_mem + L_i)
          _t1176 = _rand(1.0)
          if _tr((1.0 if _t1176 < 0.5 else 0.0)):
            _t1177 = (-12.0)
          else:
            _t1177 = 12.0
          _t1178 = _t1177
          _mset(_t1175, _t1178)
          _t1174 = _t1178
        else:
          _t1179 = _ix(v_slice_pitch_mem + L_i)
          _t1180 = 0.0
          _mset(_t1179, _t1180)
          _t1174 = _t1180
        _t1173 = _t1174
      else:
        L_ext_pct = ((L_ratio_p - 0.5) * 2.0)
        L_idx_norm = _div(L_i, L_step_len)
        if _tr((1.0 if L_idx_norm < 0.5 else 0.0)):
          _t1182 = _ix(v_slice_pitch_mem + L_i)
          _t1183 = _rand(1.0)
          if _tr((1.0 if _t1183 < 0.5 else 0.0)):
            _t1184 = (-12.0)
          else:
            _t1184 = 12.0
          _t1185 = _t1184
          _mset(_t1182, _t1185)
          _t1181 = _t1185
        else:
          L_active_double = (0.5 + (L_ext_pct * 0.5))
          if _tr((1.0 if L_idx_norm < L_active_double else 0.0)):
            _t1187 = _ix(v_slice_pitch_mem + L_i)
            _t1188 = _rand(1.0)
            if _tr((1.0 if _t1188 < 0.5 else 0.0)):
              _t1189 = (-24.0)
            else:
              _t1189 = 24.0
            _t1190 = _t1189
            _mset(_t1187, _t1190)
            _t1186 = _t1190
          else:
            _t1191 = _ix(v_slice_pitch_mem + L_i)
            _t1192 = _rand(1.0)
            if _tr((1.0 if _t1192 < 0.5 else 0.0)):
              _t1193 = (-12.0)
            else:
              _t1193 = 12.0
            _t1194 = _t1193
            _mset(_t1191, _t1194)
            _t1186 = _t1194
          _t1181 = _t1186
        _t1173 = _t1181
      _t1170 = _t1173
    L_i = (L_i + 1.0)
  return 0.0

def f_generate_slicer_sequence(L_step_len):
  global v_seq_mem, v_slicer_mode, v_trans_count, v_trans_mem
  L_i = 0.0
  L_rnd_idx = 0.0
  L_temp = 0.0
  L_p = 0.0
  if _tr((1.0 if v_trans_count > 0.0 else 0.0)):
    if _tr((1.0 if abs(v_slicer_mode - 5.0) < 0.00001 else 0.0)):
      L_i = 0.0
      for _t1197 in range(max(0, int(L_step_len))):
        _t1198 = _ix(v_seq_mem + L_i)
        _t1199 = _mget(v_trans_mem + _mod(L_i, v_trans_count))
        _mset(_t1198, _t1199)
        L_i = (L_i + 1.0)
      L_i = 0.0
      for _t1200 in range(max(0, int(L_step_len))):
        _t1201 = L_step_len
        _t1202 = _rand(_t1201)
        _t1203 = _t1202
        _t1204 = _floor(_t1203)
        L_p = _t1204
        L_temp = _mget(v_seq_mem + L_i)
        _t1205 = _ix(v_seq_mem + L_i)
        _t1206 = _mget(v_seq_mem + L_p)
        _mset(_t1205, _t1206)
        _t1207 = _ix(v_seq_mem + L_p)
        _t1208 = L_temp
        _mset(_t1207, _t1208)
        L_i = (L_i + 1.0)
      _t1196 = 0.0
    else:
      L_i = 0.0
      for _t1209 in range(max(0, int(L_step_len))):
        _t1210 = v_trans_count
        _t1211 = _rand(_t1210)
        _t1212 = _t1211
        _t1213 = _floor(_t1212)
        L_rnd_idx = _t1213
        _t1214 = _ix(v_seq_mem + L_i)
        _t1215 = _mget(v_trans_mem + L_rnd_idx)
        _mset(_t1214, _t1215)
        L_i = (L_i + 1.0)
      _t1196 = 0.0
    _t1216 = L_step_len
    _t1217 = f_update_slicer_pitches(_t1216)
    _t1195 = _t1217
  else:
    _t1195 = 0.0
  return _t1195

def f_calc_cloud_pitch(L_spread_val):
  L_ratio_p = 0.0
  L_impact_pct = 0.0
  L_ext_pct = 0.0
  L_r = 0.0
  L_ratio_p = (L_spread_val * 0.01)
  if _tr((1.0 if L_ratio_p <= 0.0001 else 0.0)):
    _t1218 = 0.0
  else:
    if _tr((1.0 if L_ratio_p <= 0.5 else 0.0)):
      L_impact_pct = (L_ratio_p * 2.0)
      _t1220 = _rand(1.0)
      if _tr((1.0 if _t1220 < L_impact_pct else 0.0)):
        _t1222 = _rand(1.0)
        if _tr((1.0 if _t1222 < 0.5 else 0.0)):
          _t1223 = (-12.0)
        else:
          _t1223 = 12.0
        _t1221 = _t1223
      else:
        _t1221 = 0.0
      _t1219 = _t1221
    else:
      L_ext_pct = ((L_ratio_p - 0.5) * 2.0)
      _t1224 = _rand(1.0)
      L_r = _t1224
      if _tr((1.0 if L_r < 0.5 else 0.0)):
        _t1226 = _rand(1.0)
        if _tr((1.0 if _t1226 < 0.5 else 0.0)):
          _t1227 = (-12.0)
        else:
          _t1227 = 12.0
        _t1225 = _t1227
      else:
        if _tr((1.0 if L_r < (0.5 + (L_ext_pct * 0.5)) else 0.0)):
          _t1229 = _rand(1.0)
          if _tr((1.0 if _t1229 < 0.5 else 0.0)):
            _t1230 = (-24.0)
          else:
            _t1230 = 24.0
          _t1228 = _t1230
        else:
          _t1231 = _rand(1.0)
          if _tr((1.0 if _t1231 < 0.5 else 0.0)):
            _t1232 = (-12.0)
          else:
            _t1232 = 12.0
          _t1228 = _t1232
        _t1225 = _t1228
      _t1219 = _t1225
    _t1218 = _t1219
  return _t1218

def f_tape_write_span(L_w_from, L_w_to, L_w_mode):
  global v_buf_len, v_degradation, v_dens_g, v_dub_g, v_dub_pan, v_feedback, v_in0, v_in1, v_left_buf, v_prev_in0, v_prev_in1, v_replace_fade, v_right_buf, v_sl_gate, v_srate, v_stereo_width, v_tape_lpf_l, v_tape_lpf_l_b, v_tape_lpf_l_c, v_tape_lpf_l_d, v_tape_lpf_r, v_tape_lpf_r_b, v_tape_lpf_r_c, v_tape_lpf_r_d
  L_k = 0.0
  L_k_end = 0.0
  L_seg_a = 0.0
  L_seg_b = 0.0
  L_wgt = 0.0
  L_tn = 0.0
  L_vl = 0.0
  L_vr = 0.0
  L_w2 = 0.0
  L_oldl = 0.0
  L_oldr = 0.0
  L_steps = 0.0
  L_total_span = 0.0
  L_fb = 0.0
  L_targetl = 0.0
  L_targetr = 0.0
  L_dev = 0.0
  L_cutoff = 0.0
  L_lpf_alpha = 0.0
  L_deg = 0.0
  L_deg_amt = 0.0
  L_p_angle = 0.0
  L_gl = 0.0
  L_gr = 0.0
  L_mono_src = 0.0
  L_clippedl = 0.0
  L_clippedr = 0.0
  L_drive = 0.0
  L_souffle = 0.0
  L_deg = v_degradation
  if _tr((1.0 if L_w_to > L_w_from else 0.0)):
    _t1234 = L_w_from
    _t1235 = _floor(_t1234)
    L_k = _t1235
    _t1236 = L_w_to
    _t1237 = _floor(_t1236)
    L_k_end = _t1237
    if _tr((1.0 if L_k_end < L_k else 0.0)):
      L_k_end = L_k
      _t1238 = L_k_end
    else:
      _t1238 = 0.0
    _t1239 = ((L_k_end - L_k) + 1.0)
    _t1240 = min(_t1239, 24.0)
    L_steps = _t1240
    _t1241 = (L_w_to - L_w_from)
    _t1242 = max(_t1241, 0.0001)
    L_total_span = _t1242
    for _t1243 in range(max(0, int(L_steps))):
      if _tr((1.0 if L_k < v_buf_len else 0.0)):
        _t1245 = L_w_from
        _t1246 = L_k
        _t1247 = max(_t1245, _t1246)
        L_seg_a = _t1247
        _t1248 = L_w_to
        _t1249 = (L_k + 1.0)
        _t1250 = min(_t1248, _t1249)
        L_seg_b = _t1250
        _t1252 = (((L_seg_b - L_seg_a) * v_dens_g) * v_sl_gate)
        if _tr((1.0 if abs(L_w_mode - 1.0) < 0.00001 else 0.0)):
          _t1251 = v_dub_g
        else:
          _t1251 = 1.0
        L_wgt = (_t1252 * _t1251)
        if _tr((1.0 if L_wgt > 0.0 else 0.0)):
          L_tn = _div((((L_seg_a + L_seg_b) * 0.5) - L_w_from), L_total_span)
          L_vl = (v_prev_in0 + ((v_in0 - v_prev_in0) * L_tn))
          L_vr = (v_prev_in1 + ((v_in1 - v_prev_in1) * L_tn))
          if _tr((1.0 if v_stereo_width > 0.0001 else 0.0)):
            L_p_angle = ((((v_dub_pan * v_stereo_width) + 1.0) * 0.25) * 3.141592653589793)
            _t1255 = L_p_angle
            _t1256 = math.cos(_t1255)
            L_gl = (_t1256 * 1.414)
            _t1257 = L_p_angle
            _t1258 = math.sin(_t1257)
            L_gr = (_t1258 * 1.414)
            L_mono_src = ((L_vl + L_vr) * 0.5)
            L_vl = (L_mono_src * L_gl)
            L_vr = (L_mono_src * L_gr)
            _t1254 = L_vr
          else:
            _t1254 = 0.0
          if _tr((1.0 if abs(L_w_mode - 2.0) < 0.00001 else 0.0)):
            L_w2 = (L_wgt * v_replace_fade)
            L_oldl = _mget(v_left_buf + L_k)
            L_oldr = _mget(v_right_buf + L_k)
            L_targetl = ((L_oldl * (1.0 - L_w2)) + (L_vl * L_w2))
            L_targetr = ((L_oldr * (1.0 - L_w2)) + (L_vr * L_w2))
            _t1259 = L_targetr
          else:
            L_fb = (1.0 - (L_wgt * (1.0 - v_feedback)))
            L_oldl = _mget(v_left_buf + L_k)
            L_oldr = _mget(v_right_buf + L_k)
            L_targetl = ((L_oldl * L_fb) + (L_vl * L_wgt))
            L_targetr = ((L_oldr * L_fb) + (L_vr * L_wgt))
            _t1259 = L_targetr
          _t1260 = 1.0 if _tr((1.0 if L_deg > 0.0001 else 0.0)) else 0.0
          if _t1260:
            _t1261 = (v_feedback - 1.0)
            _t1262 = abs(_t1261)
            _t1260 = 1.0 if _tr((1.0 if _t1262 > 0.001 else 0.0)) else 0.0
          if _tr(_t1260):
            _t1266 = L_deg
            _t1264 = (v_feedback - 1.0)
            _t1265 = abs(_t1264)
            L_deg_amt = (_t1266 * _t1265)
            L_drive = (1.0 + (L_deg_amt * 4.0))
            _t1267 = (L_targetl * L_drive)
            _t1268 = f_fast_tanh(_t1267)
            L_targetl = _div(_t1268, L_drive)
            _t1269 = (L_targetr * L_drive)
            _t1270 = f_fast_tanh(_t1269)
            L_targetr = _div(_t1270, L_drive)
            _t1271 = ((-3.2) * L_deg_amt)
            _t1272 = _exp(_t1271)
            _t1273 = (20000.0 * _t1272)
            _t1274 = max(200.0, _t1273)
            L_cutoff = _t1274
            _t1275 = _div((((-2.0) * 3.141592653589793) * L_cutoff), v_srate)
            _t1276 = _exp(_t1275)
            L_lpf_alpha = (1.0 - _t1276)
            v_tape_lpf_l = (v_tape_lpf_l + (L_lpf_alpha * (L_targetl - v_tape_lpf_l)))
            v_tape_lpf_l_b = (v_tape_lpf_l_b + (L_lpf_alpha * (v_tape_lpf_l - v_tape_lpf_l_b)))
            v_tape_lpf_l_c = (v_tape_lpf_l_c + (L_lpf_alpha * (v_tape_lpf_l_b - v_tape_lpf_l_c)))
            v_tape_lpf_l_d = (v_tape_lpf_l_d + (L_lpf_alpha * (v_tape_lpf_l_c - v_tape_lpf_l_d)))
            v_tape_lpf_r = (v_tape_lpf_r + (L_lpf_alpha * (L_targetr - v_tape_lpf_r)))
            v_tape_lpf_r_b = (v_tape_lpf_r_b + (L_lpf_alpha * (v_tape_lpf_r - v_tape_lpf_r_b)))
            v_tape_lpf_r_c = (v_tape_lpf_r_c + (L_lpf_alpha * (v_tape_lpf_r_b - v_tape_lpf_r_c)))
            v_tape_lpf_r_d = (v_tape_lpf_r_d + (L_lpf_alpha * (v_tape_lpf_r_c - v_tape_lpf_r_d)))
            L_targetl = ((L_targetl * (1.0 - L_deg_amt)) + (v_tape_lpf_l_d * L_deg_amt))
            L_targetr = ((L_targetr * (1.0 - L_deg_amt)) + (v_tape_lpf_r_d * L_deg_amt))
            _t1277 = _rand(2.0)
            L_souffle = (((_t1277 - 1.0) * 0.0001) * L_deg_amt)
            L_targetl = (L_targetl + L_souffle)
            L_targetr = (L_targetr + L_souffle)
            _t1263 = L_targetr
          else:
            _t1263 = 0.0
          _t1278 = _ix(v_left_buf + L_k)
          _t1279 = L_targetl
          _mset(_t1278, _t1279)
          _t1280 = _ix(v_right_buf + L_k)
          _t1281 = L_targetr
          _mset(_t1280, _t1281)
          _t1253 = _t1281
        else:
          _t1253 = 0.0
        _t1244 = _t1253
      else:
        _t1244 = 0.0
      L_k = (L_k + 1.0)
    _t1233 = 0.0
  else:
    _t1233 = 0.0
  return _t1233

def f_rec_preroll(L_d):
  global v_dirty_len, v_ih_l, v_ih_mask, v_ih_n, v_ih_r, v_ih_size, v_in0, v_in1, v_pos, v_prev_in0, v_prev_in1, v_rec_ref_kind, v_rec_ref_len, v_rec_ref_ph, v_rec_speed, v_srate
  L_k = 0.0
  L_j = 0.0
  L_p = 0.0
  L_s0 = 0.0
  L_s1 = 0.0
  L_q0 = 0.0
  L_q1 = 0.0
  _t1282 = L_d
  _t1283 = (v_srate * 0.1)
  _t1284 = min(_t1282, _t1283)
  _t1285 = _t1284
  _t1286 = (v_ih_size - 2.0)
  _t1287 = min(_t1285, _t1286)
  _t1288 = _t1287
  _t1289 = _floor(_t1288)
  L_d = _t1289
  if _tr((1.0 if L_d > 0.0 else 0.0)):
    L_s0 = v_in0
    L_s1 = v_in1
    L_q0 = v_prev_in0
    L_q1 = v_prev_in1
    L_j = float(int(((v_ih_n - L_d) - 1.0)) & int(v_ih_mask))
    v_in0 = _mget(v_ih_l + L_j)
    v_in1 = _mget(v_ih_r + L_j)
    L_p = 0.0
    L_k = 0.0
    for _t1291 in range(max(0, int(L_d))):
      v_prev_in0 = v_in0
      v_prev_in1 = v_in1
      L_j = float(int(((v_ih_n - L_d) + L_k)) & int(v_ih_mask))
      v_in0 = _mget(v_ih_l + L_j)
      v_in1 = _mget(v_ih_r + L_j)
      _t1292 = L_p
      _t1293 = (L_p + v_rec_speed)
      _t1294 = f_tape_write_span(_t1292, _t1293, 1.0)
      L_p = (L_p + v_rec_speed)
      L_k = (L_k + 1.0)
    v_in0 = L_s0
    v_in1 = L_s1
    v_prev_in0 = L_q0
    v_prev_in1 = L_q1
    v_pos = L_p
    _t1295 = v_dirty_len
    _t1296 = v_pos
    _t1297 = max(_t1295, _t1296)
    v_dirty_len = _t1297
    _t1298 = 1.0 if _tr((1.0 if v_rec_ref_kind > 0.0 else 0.0)) else 0.0
    if _t1298:
      _t1298 = 1.0 if _tr((1.0 if v_rec_ref_len > 0.0 else 0.0)) else 0.0
    if _tr(_t1298):
      v_rec_ref_ph = (v_rec_ref_ph - L_d)
      _t1302 = v_rec_ref_len
      _t1300 = _div(v_rec_ref_ph, v_rec_ref_len)
      _t1301 = _floor(_t1300)
      v_rec_ref_ph = (v_rec_ref_ph - (_t1302 * _t1301))
      _t1299 = v_rec_ref_ph
    else:
      _t1299 = 0.0
    _t1290 = _t1299
  else:
    _t1290 = 0.0
  return _t1290

def f_tws(L_a, L_b, L_m):
  global v_eff_end, v_eff_len, v_eff_start, v_wr_off
  L_a2 = 0.0
  L_b2 = 0.0
  _t1303 = 1.0 if _tr((1.0 if abs(v_wr_off - 0.0) < 0.00001 else 0.0)) else 0.0
  if not _t1303:
    _t1303 = 1.0 if _tr((1.0 if v_eff_len <= 0.0 else 0.0)) else 0.0
  if _tr(_t1303):
    _t1305 = L_a
    _t1306 = L_b
    _t1307 = L_m
    _t1308 = f_tape_write_span(_t1305, _t1306, _t1307)
    _t1304 = _t1308
  else:
    L_a2 = (L_a + v_wr_off)
    L_b2 = (L_b + v_wr_off)
    if _tr((1.0 if L_a2 >= v_eff_end else 0.0)):
      L_a2 = (L_a2 - v_eff_len)
      L_b2 = (L_b2 - v_eff_len)
      _t1309 = L_b2
    else:
      if _tr((1.0 if L_a2 < v_eff_start else 0.0)):
        L_a2 = (L_a2 + v_eff_len)
        L_b2 = (L_b2 + v_eff_len)
        _t1310 = L_b2
      else:
        _t1310 = 0.0
      _t1309 = _t1310
    if _tr((1.0 if L_b2 > v_eff_end else 0.0)):
      _t1312 = L_a2
      _t1313 = (v_eff_end - 0.0001)
      _t1314 = L_m
      _t1315 = f_tape_write_span(_t1312, _t1313, _t1314)
      _t1316 = v_eff_start
      _t1317 = (L_b2 - v_eff_len)
      _t1318 = L_m
      _t1319 = f_tape_write_span(_t1316, _t1317, _t1318)
      _t1311 = _t1319
    else:
      _t1320 = L_a2
      _t1321 = L_b2
      _t1322 = L_m
      _t1323 = f_tape_write_span(_t1320, _t1321, _t1322)
      _t1311 = _t1323
    _t1304 = _t1311
  return _t1304

def f_write_move(L_o, L_n, L_wrapped, L_rev, L_wmode):
  global v_eff_end, v_eff_start, v_pingpong_on
  if _tr(L_wrapped):
    if _tr(v_pingpong_on):
      if _tr(L_rev):
        _t1327 = v_eff_start
        _t1328 = L_o
        _t1329 = L_wmode
        _t1330 = f_tws(_t1327, _t1328, _t1329)
        _t1331 = v_eff_start
        _t1332 = L_n
        _t1333 = L_wmode
        _t1334 = f_tws(_t1331, _t1332, _t1333)
        _t1326 = _t1334
      else:
        _t1335 = L_o
        _t1336 = (v_eff_end - 0.0001)
        _t1337 = L_wmode
        _t1338 = f_tws(_t1335, _t1336, _t1337)
        _t1339 = L_n
        _t1340 = (v_eff_end - 0.0001)
        _t1341 = L_wmode
        _t1342 = f_tws(_t1339, _t1340, _t1341)
        _t1326 = _t1342
      _t1325 = _t1326
    else:
      if _tr(L_rev):
        _t1344 = L_n
        _t1345 = (v_eff_end - 0.0001)
        _t1346 = L_wmode
        _t1347 = f_tws(_t1344, _t1345, _t1346)
        _t1348 = v_eff_start
        _t1349 = L_o
        _t1350 = L_wmode
        _t1351 = f_tws(_t1348, _t1349, _t1350)
        _t1343 = _t1351
      else:
        _t1352 = L_o
        _t1353 = (v_eff_end - 0.0001)
        _t1354 = L_wmode
        _t1355 = f_tws(_t1352, _t1353, _t1354)
        _t1356 = v_eff_start
        _t1357 = L_n
        _t1358 = L_wmode
        _t1359 = f_tws(_t1356, _t1357, _t1358)
        _t1343 = _t1359
      _t1325 = _t1343
    _t1324 = _t1325
  else:
    if _tr(L_rev):
      _t1361 = L_n
      _t1362 = v_eff_start
      _t1363 = max(_t1361, _t1362)
      _t1364 = _t1363
      _t1365 = L_o
      _t1366 = (v_eff_end - 0.0001)
      _t1367 = min(_t1365, _t1366)
      _t1368 = _t1367
      _t1369 = L_wmode
      _t1370 = f_tws(_t1364, _t1368, _t1369)
      _t1360 = _t1370
    else:
      _t1371 = L_o
      _t1372 = v_eff_start
      _t1373 = max(_t1371, _t1372)
      _t1374 = _t1373
      _t1375 = L_n
      _t1376 = (v_eff_end - 0.0001)
      _t1377 = min(_t1375, _t1376)
      _t1378 = _t1377
      _t1379 = L_wmode
      _t1380 = f_tws(_t1374, _t1378, _t1379)
      _t1360 = _t1380
    _t1324 = _t1360
  return _t1324

def f_slc_move(L_wmode):
  global v_eff_end, v_eff_len, v_eff_start, v_effective_rev, v_link_eff, v_pos, v_sl_gate, v_sm_speed, v_sw_on, v_sw_pos, v_varispeed
  L_o = 0.0
  L_n = 0.0
  L_dir = 0.0
  L_sg = 0.0
  L_adv = 0.0
  if _tr(v_effective_rev):
    _t1381 = (-1.0)
  else:
    _t1381 = 1.0
  L_dir = _t1381
  if _tr(v_link_eff):
    _t1382 = v_varispeed
  else:
    _t1382 = v_sm_speed
  _t1383 = _t1382
  _t1384 = max(0.01, _t1383)
  L_adv = _t1384
  if _tr((0.0 if _tr(v_sw_on) else 1.0)):
    v_sw_on = 1.0
    _t1386 = v_eff_start
    _t1387 = (v_eff_end - 1.0)
    _t1388 = v_pos
    _t1389 = min(_t1387, _t1388)
    _t1390 = _t1389
    _t1391 = max(_t1386, _t1390)
    v_sw_pos = _t1391
    _t1385 = v_sw_pos
  else:
    _t1385 = 0.0
  L_o = v_sw_pos
  L_n = (L_o + (L_dir * L_adv))
  L_sg = v_sl_gate
  v_sl_gate = 1.0
  if _tr((1.0 if L_dir > 0.0 else 0.0)):
    _t1392 = (1.0 if L_n >= v_eff_end else 0.0)
  else:
    _t1392 = (1.0 if L_n < v_eff_start else 0.0)
  if _tr(_t1392):
    if _tr((1.0 if L_dir > 0.0 else 0.0)):
      _t1394 = (L_n - v_eff_len)
    else:
      _t1394 = (L_n + v_eff_len)
    L_n = _t1394
    _t1395 = L_o
    _t1396 = L_n
    _t1397 = v_effective_rev
    _t1398 = L_wmode
    _t1399 = f_write_move(_t1395, _t1396, 1.0, _t1397, _t1398)
    _t1393 = _t1399
  else:
    _t1400 = L_o
    _t1401 = L_n
    _t1402 = v_effective_rev
    _t1403 = L_wmode
    _t1404 = f_write_move(_t1400, _t1401, 0.0, _t1402, _t1403)
    _t1393 = _t1404
  v_sl_gate = L_sg
  v_sw_pos = L_n
  return v_sw_pos

def f_slw_move(L_wmode):
  global v_eff_len, v_effective_rev, v_sl_gate, v_slw_last, v_slx_pos
  L_o = 0.0
  L_n = 0.0
  L_d = 0.0
  L_sg = 0.0
  L_o = v_slw_last
  L_n = v_slx_pos
  v_slw_last = L_n
  _t1405 = 1.0 if _tr((1.0 if L_o >= 0.0 else 0.0)) else 0.0
  if _t1405:
    _t1405 = 1.0 if _tr((1.0 if v_eff_len > 16.0 else 0.0)) else 0.0
  if _tr(_t1405):
    L_sg = v_sl_gate
    v_sl_gate = 1.0
    if _tr(v_effective_rev):
      _t1407 = (L_o - L_n)
    else:
      _t1407 = (L_n - L_o)
    L_d = _t1407
    _t1408 = 1.0 if _tr((1.0 if L_d >= 0.0 else 0.0)) else 0.0
    if _t1408:
      _t1408 = 1.0 if _tr((1.0 if L_d <= 8.0 else 0.0)) else 0.0
    if _tr(_t1408):
      _t1410 = L_o
      _t1411 = L_n
      _t1412 = v_effective_rev
      _t1413 = L_wmode
      _t1414 = f_write_move(_t1410, _t1411, 0.0, _t1412, _t1413)
      _t1409 = _t1414
    else:
      if _tr((1.0 if L_d < (0.0 - (v_eff_len - 8.0)) else 0.0)):
        _t1416 = L_o
        _t1417 = L_n
        _t1418 = v_effective_rev
        _t1419 = L_wmode
        _t1420 = f_write_move(_t1416, _t1417, 1.0, _t1418, _t1419)
        _t1415 = _t1420
      else:
        _t1415 = 0.0
      _t1409 = _t1415
    v_sl_gate = L_sg
    _t1406 = v_sl_gate
  else:
    _t1406 = 0.0
  return _t1406

def f_hermite(L_frac, L_y0, L_y1, L_y2, L_y3):
  L_c0 = 0.0
  L_c1 = 0.0
  L_c2 = 0.0
  L_c3 = 0.0
  L_c0 = L_y1
  L_c1 = (0.5 * (L_y2 - L_y0))
  L_c2 = (((L_y0 - (2.5 * L_y1)) + (2.0 * L_y2)) - (0.5 * L_y3))
  L_c3 = ((0.5 * (L_y3 - L_y0)) + (1.5 * (L_y1 - L_y2)))
  return (L_c0 + (L_frac * (L_c1 + (L_frac * (L_c2 + (L_frac * L_c3))))))

def f_xf_begin(L_len, L_eqp):
  global v_pd_arm, v_rd_last_g, v_rd_last_l, v_rd_last_p, v_rd_last_pamt, v_rd_last_pan, v_rd_last_r, v_rd_last_st, v_rd_last_we, v_rd_last_ws, v_rd_valid, v_xf_eqp, v_xf_g, v_xf_inc, v_xf_k, v_xf_l, v_xf_on, v_xf_p, v_xf_pamt, v_xf_pan, v_xf_r, v_xf_st, v_xf_we, v_xf_ws
  if _tr(v_rd_valid):
    _t1422 = 1.0 if _tr(v_xf_on) else 0.0
    if _t1422:
      _t1422 = 1.0 if _tr((1.0 if v_xf_k < 0.5 else 0.0)) else 0.0
    if _tr((0.0 if _tr(_t1422) else 1.0)):
      v_xf_l = v_rd_last_l
      v_xf_r = v_rd_last_r
      v_xf_p = (v_rd_last_p + v_rd_last_st)
      v_xf_st = v_rd_last_st
      v_xf_ws = v_rd_last_ws
      v_xf_we = v_rd_last_we
      v_xf_g = v_rd_last_g
      v_xf_pan = v_rd_last_pan
      v_xf_pamt = v_rd_last_pamt
      _t1423 = v_xf_pamt
    else:
      _t1423 = 0.0
    if _tr(v_xf_on):
      v_pd_arm = 1.0
      _t1424 = v_pd_arm
    else:
      _t1424 = 0.0
    v_xf_on = 1.0
    v_xf_k = 0.0
    _t1425 = L_len
    _t1426 = max(1.0, _t1425)
    v_xf_inc = _div(1.0, _t1426)
    v_xf_eqp = L_eqp
    _t1421 = v_xf_eqp
  else:
    v_pd_arm = 1.0
    _t1421 = v_pd_arm
  return _t1421

def f_pan_lr(L_l, L_r, L_pn, L_amt):
  global v_pan_ol, v_pan_or
  L_a = 0.0
  L_gl = 0.0
  L_gr = 0.0
  L_m = 0.0
  L_a = ((((L_pn * L_amt) + 1.0) * 0.25) * 3.141592653589793)
  _t1427 = L_a
  _t1428 = math.cos(_t1427)
  _t1429 = (_t1428 * 1.414)
  _t1430 = min(1.0, _t1429)
  L_gl = _t1430
  _t1431 = L_a
  _t1432 = math.sin(_t1431)
  _t1433 = (_t1432 * 1.414)
  _t1434 = min(1.0, _t1433)
  L_gr = _t1434
  L_m = ((L_l + L_r) * 0.5)
  v_pan_ol = ((L_l * (1.0 - L_amt)) + ((L_m * L_gl) * L_amt))
  v_pan_or = ((L_r * (1.0 - L_amt)) + ((L_m * L_gr) * L_amt))
  return v_pan_or

def f_df_ap(L_b, L_x, L_g):
  L_i = 0.0
  L_v = 0.0
  L_y = 0.0
  L_i = _mget(L_b + 0.0)
  L_v = _mget(L_b + (2.0 + L_i))
  L_y = (L_v - (L_g * L_x))
  _t1435 = _ix(L_b + (2.0 + L_i))
  _t1436 = (L_x + (L_g * L_y))
  _mset(_t1435, _t1436)
  L_i = (L_i + 1.0)
  if _tr((1.0 if L_i >= _mget(L_b + 1.0) else 0.0)):
    L_i = 0.0
    _t1437 = L_i
  else:
    _t1437 = 0.0
  _t1438 = _ix(L_b + 0.0)
  _t1439 = L_i
  _mset(_t1438, _t1439)
  return L_y

def f_df_rd(L_b):
  return _mget(L_b + (2.0 + _mget(L_b + 0.0)))

def f_df_wr(L_b, L_x):
  L_i = 0.0
  L_i = _mget(L_b + 0.0)
  _t1440 = _ix(L_b + (2.0 + L_i))
  _t1441 = L_x
  _mset(_t1440, _t1441)
  L_i = (L_i + 1.0)
  if _tr((1.0 if L_i >= _mget(L_b + 1.0) else 0.0)):
    L_i = 0.0
    _t1442 = L_i
  else:
    _t1442 = 0.0
  _t1443 = _ix(L_b + 0.0)
  _t1444 = L_i
  _mset(_t1443, _t1444)
  return _t1444

def f_cl_spawn():
  global v_cl_a, v_cl_center, v_cl_max, v_cl_mem, v_cl_stride, v_cloud_freeze, v_cloud_pitch_spread, v_cloud_size, v_cloud_spread, v_eff_end, v_eff_start, v_effective_rev, v_frz_ready, v_pitch_ratio, v_srate, v_stereo_width
  L_gi = 0.0
  L_gb = 0.0
  L_fs = 0.0
  L_a = 0.0
  L_sz = 0.0
  L_off = 0.0
  L_r = 0.0
  L_dir = 0.0
  L_ws = 0.0
  L_we = 0.0
  L_wl = 0.0
  L_spray = 0.0
  L_st = 0.0
  L_span = 0.0
  L_sh = 0.0
  L_pn = 0.0
  L_pa = 0.0
  L_fc = 0.0
  L_fs = (-1.0)
  L_gi = 0.0
  for _t1445 in range(max(0, int(v_cl_max))):
    L_gb = (v_cl_mem + (L_gi * v_cl_stride))
    _t1446 = 1.0 if _tr((1.0 if L_fs < 0.0 else 0.0)) else 0.0
    if _t1446:
      _t1446 = 1.0 if _tr((1.0 if abs(_mget(L_gb + 2.0) - 0.0) < 0.00001 else 0.0)) else 0.0
    if _tr(_t1446):
      L_fs = L_gi
      _t1447 = L_fs
    else:
      _t1447 = 0.0
    L_gi = (L_gi + 1.0)
  if _tr((1.0 if L_fs >= 0.0 else 0.0)):
    L_gb = (v_cl_mem + (L_fs * v_cl_stride))
    L_a = v_cl_a
    _t1453 = ((v_srate * 0.001) * v_cloud_size)
    _t1450 = (L_a * 0.7)
    _t1449 = _rand(2.0)
    _t1451 = (_t1450 * (_t1449 - 1.0))
    _t1452 = _exp(_t1451)
    _t1454 = (_t1453 * _t1452)
    _t1455 = max(16.0, _t1454)
    L_sz = _t1455
    _t1456 = _rand(2.0)
    L_off = (((_t1456 - 1.0) * L_a) * 0.35)
    _t1457 = 1.0 if _tr((1.0 if L_a > 0.4 else 0.0)) else 0.0
    if _t1457:
      _t1458 = _rand(1.0)
      _t1457 = 1.0 if _tr((1.0 if _t1458 < (L_a - 0.4) else 0.0)) else 0.0
    if _tr(_t1457):
      _t1460 = _rand(1.0)
      L_r = _t1460
      if _tr((1.0 if L_r < 0.35 else 0.0)):
        _t1461 = 12.0
      else:
        if _tr((1.0 if L_r < 0.6 else 0.0)):
          _t1462 = (-12.0)
        else:
          if _tr((1.0 if L_r < 0.8 else 0.0)):
            _t1463 = 7.0
          else:
            _t1463 = (-5.0)
          _t1462 = _t1463
        _t1461 = _t1462
      L_off = (L_off + _t1461)
      _t1459 = L_off
    else:
      _t1459 = 0.0
    _t1464 = v_cloud_pitch_spread
    _t1465 = f_calc_cloud_pitch(_t1464)
    L_off = (L_off + _t1465)
    _t1466 = (-36.0)
    _t1467 = L_off
    _t1468 = min(36.0, _t1467)
    _t1469 = _t1468
    _t1470 = max(_t1466, _t1469)
    L_off = _t1470
    if _tr(v_effective_rev):
      _t1471 = (-1.0)
    else:
      _t1471 = 1.0
    L_dir = _t1471
    _t1472 = 1.0 if _tr((1.0 if L_a > 0.6 else 0.0)) else 0.0
    if _t1472:
      _t1473 = _rand(1.0)
      _t1472 = 1.0 if _tr((1.0 if _t1473 < ((L_a - 0.6) * 0.75) else 0.0)) else 0.0
    if _tr(_t1472):
      L_dir = (-L_dir)
      _t1474 = L_dir
    else:
      _t1474 = 0.0
    L_r = (v_pitch_ratio * _pow(2.0, _div(L_off, 12.0)))
    L_ws = v_eff_start
    L_we = v_eff_end
    _t1475 = (L_we - L_ws)
    _t1476 = max(16.0, _t1475)
    L_wl = _t1476
    _t1477 = (L_wl * 0.5)
    _t1478 = ((v_srate * 0.005) + (((v_cloud_spread + (L_a * L_a)) * L_wl) * 0.5))
    _t1479 = min(_t1477, _t1478)
    L_spray = _t1479
    _t1481 = v_cl_center
    _t1480 = _rand(2.0)
    L_st = (_t1481 + ((_t1480 - 1.0) * L_spray))
    L_st = (L_st - L_ws)
    _t1482 = _div(L_st, L_wl)
    _t1483 = _floor(_t1482)
    L_st = (L_st - (_t1483 * L_wl))
    L_st = (L_st + L_ws)
    L_span = (L_r * L_sz)
    if _tr((1.0 if L_span < (L_wl * 0.98) else 0.0)):
      if _tr((1.0 if L_dir > 0.0 else 0.0)):
        if _tr((1.0 if (L_st + L_span) >= L_we else 0.0)):
          L_st = ((L_we - L_span) - 1.0)
          _t1486 = L_st
        else:
          _t1486 = 0.0
        _t1485 = _t1486
      else:
        if _tr((1.0 if (L_st - L_span) < L_ws else 0.0)):
          L_st = ((L_ws + L_span) + 1.0)
          _t1487 = L_st
        else:
          _t1487 = 0.0
        _t1485 = _t1487
      _t1488 = L_ws
      _t1489 = (L_we - 1.0)
      _t1490 = L_st
      _t1491 = min(_t1489, _t1490)
      _t1492 = _t1491
      _t1493 = max(_t1488, _t1492)
      L_st = _t1493
      _t1484 = L_st
    else:
      _t1484 = 0.0
    _t1494 = ((L_a - 0.5) * 2.0)
    _t1495 = min(1.0, _t1494)
    _t1496 = _t1495
    _t1497 = max(0.0, _t1496)
    L_sh = _t1497
    _t1498 = _rand(2.0)
    L_pn = ((_t1498 - 1.0) * v_stereo_width)
    L_pa = (((L_pn + 1.0) * 0.25) * 3.141592653589793)
    if _tr((1.0 if L_r > 1.05 else 0.0)):
      _t1503 = ((-2.0) * 3.141592653589793)
      _t1500 = _div((0.45 * v_srate), L_r)
      _t1501 = (0.45 * v_srate)
      _t1502 = min(_t1500, _t1501)
      _t1504 = _div((_t1503 * _t1502), v_srate)
      _t1505 = _exp(_t1504)
      _t1499 = (1.0 - _t1505)
    else:
      _t1499 = 1.0
    L_fc = _t1499
    _t1506 = _ix(L_gb + 0.0)
    _t1507 = L_st
    _mset(_t1506, _t1507)
    _t1508 = _ix(L_gb + 1.0)
    _t1509 = 0.0
    _mset(_t1508, _t1509)
    _t1510 = _ix(L_gb + 2.0)
    _t1511 = 1.0
    _mset(_t1510, _t1511)
    _t1512 = _ix(L_gb + 3.0)
    _t1513 = L_sz
    _mset(_t1512, _t1513)
    _t1514 = _ix(L_gb + 4.0)
    _t1515 = L_pn
    _mset(_t1514, _t1515)
    _t1516 = _ix(L_gb + 5.0)
    _t1517 = (L_dir * L_r)
    _mset(_t1516, _t1517)
    _t1518 = _ix(L_gb + 6.0)
    _t1519 = L_pa
    _t1520 = math.cos(_t1519)
    _t1521 = (_t1520 * 1.414)
    _mset(_t1518, _t1521)
    _t1522 = _ix(L_gb + 7.0)
    _t1523 = L_pa
    _t1524 = math.sin(_t1523)
    _t1525 = (_t1524 * 1.414)
    _mset(_t1522, _t1525)
    _t1526 = _ix(L_gb + 8.0)
    _t1527 = (0.5 - (0.45 * L_sh))
    _mset(_t1526, _t1527)
    _t1528 = _ix(L_gb + 9.0)
    _t1529 = (1.0 + (3.0 * L_sh))
    _mset(_t1528, _t1529)
    _t1530 = _ix(L_gb + 10.0)
    _t1531 = L_fc
    _mset(_t1530, _t1531)
    _t1532 = _ix(L_gb + 11.0)
    _t1533 = 0.0
    _mset(_t1532, _t1533)
    _t1534 = _ix(L_gb + 12.0)
    _t1535 = 0.0
    _mset(_t1534, _t1535)
    _t1536 = _ix(L_gb + 13.0)
    _t1537 = 0.0
    _mset(_t1536, _t1537)
    _t1538 = _ix(L_gb + 14.0)
    _t1539 = 0.0
    _mset(_t1538, _t1539)
    _t1540 = _ix(L_gb + 15.0)
    _t1541 = 1.0 if _tr((1.0 if v_cloud_freeze >= 0.5 else 0.0)) else 0.0
    if _t1541:
      _t1541 = 1.0 if _tr(v_frz_ready) else 0.0
    if _tr(_t1541):
      _t1542 = 1.0
    else:
      _t1542 = 0.0
    _t1543 = _t1542
    _mset(_t1540, _t1543)
    _t1448 = _t1543
  else:
    _t1448 = 0.0
  return _t1448

def f_trigger_pos_jump(L_new_target):
  global v_length, v_loop_start, v_loop_width, v_old_pos_ptr, v_pos, v_slice_att, v_slice_att_eff_ms, v_slice_att_step, v_slice_decay_ms, v_slice_decay_samples, v_slice_decay_step, v_slice_env, v_slice_hold, v_slice_pan, v_srate, v_xfade_pos_active, v_xfade_pos_count
  if _tr((1.0 if v_length > 0.0 else 0.0)):
    v_slice_hold = 0.0
    v_old_pos_ptr = v_pos
    _t1545 = v_loop_start
    _t1546 = (v_loop_start + v_loop_width)
    _t1547 = L_new_target
    _t1548 = min(_t1546, _t1547)
    _t1549 = _t1548
    _t1550 = max(_t1545, _t1549)
    v_pos = _t1550
    v_xfade_pos_active = 0.0
    v_xfade_pos_count = 0.0
    v_slice_env = 1.0
    if _tr((1.0 if v_slice_att_eff_ms > 0.0 else 0.0)):
      _t1551 = 0.0
    else:
      _t1551 = 1.0
    v_slice_att = _t1551
    _t1552 = ((v_srate * v_slice_att_eff_ms) * 0.001)
    _t1553 = max(1.0, _t1552)
    v_slice_att_step = _div(1.0, _t1553)
    _t1554 = (v_srate * (v_slice_decay_ms * 0.001))
    _t1555 = max(2.0, _t1554)
    v_slice_decay_samples = _t1555
    if _tr((1.0 if v_slice_decay_ms > 1950.0 else 0.0)):
      _t1556 = 0.0
    else:
      _t1556 = _div(1.0, v_slice_decay_samples)
    v_slice_decay_step = _t1556
    _t1557 = _rand(2.0)
    v_slice_pan = (_t1557 - 1.0)
    _t1544 = v_slice_pan
  else:
    _t1544 = 0.0
  return _t1544

def f_slicer_fire(L_tp, L_p_offset):
  global v_current_slice_pitch, v_delay_len, v_effective_rev, v_length, v_loop_start, v_loop_width, v_pos, v_sl_hi, v_sl_lo, v_sl_pre_t, v_sl_run, v_slice_hold, v_srate, v_trans_count, v_trans_mem, v_varispeed, v_xf_len_slice
  L_i = 0.0
  L_nx = 0.0
  L_st = 0.0
  L_rr = 0.0
  L_dr = 0.0
  L_pre = 0.0
  L_nx = (v_loop_start + v_loop_width)
  L_i = 0.0
  for _t1558 in range(max(0, int(v_trans_count))):
    _t1559 = 1.0 if _tr((1.0 if _mget(v_trans_mem + L_i) > (L_tp + 1.0) else 0.0)) else 0.0
    if _t1559:
      _t1559 = 1.0 if _tr((1.0 if _mget(v_trans_mem + L_i) < L_nx else 0.0)) else 0.0
    if _tr(_t1559):
      L_nx = _mget(v_trans_mem + L_i)
      _t1560 = L_nx
    else:
      _t1560 = 0.0
    L_i = (L_i + 1.0)
  v_sl_lo = L_tp
  _t1561 = L_nx
  _t1562 = (L_tp + (v_srate * 0.005))
  _t1563 = max(_t1561, _t1562)
  v_sl_hi = _t1563
  if _tr(v_effective_rev):
    _t1564 = (-1.0)
  else:
    _t1564 = 1.0
  L_dr = _t1564
  if _tr(v_effective_rev):
    _t1565 = 0.0
  else:
    _t1565 = v_sl_pre_t
  L_pre = _t1565
  _t1566 = (v_varispeed * _pow(2.0, _div(L_p_offset, 12.0)))
  _t1567 = max(0.0001, _t1566)
  L_rr = _t1567
  if _tr(v_effective_rev):
    _t1568 = v_sl_hi
  else:
    _t1568 = v_sl_lo
  L_st = _t1568
  if _tr((1.0 if v_length > 0.0 else 0.0)):
    _t1570 = v_xf_len_slice
    _t1571 = f_xf_begin(_t1570, 1.0)
    _t1572 = L_st
    _t1573 = f_trigger_pos_jump(_t1572)
    v_pos = (L_st - (L_dr * ((L_rr * L_pre) + v_delay_len)))
    v_slice_hold = L_pre
    _t1569 = v_slice_hold
  else:
    _t1569 = 0.0
  v_current_slice_pitch = L_p_offset
  v_sl_run = 1.0
  return v_sl_run

def f_dub_slice_restart(L_fwd):
  global v_max_wgrains, v_wg_mem, v_wg_prev_ok, v_wg_stride, v_wg_timer
  L_gi = 0.0
  L_gb = 0.0
  _t1574 = L_fwd
  _t1575 = f_dub_commit_begin(_t1574)
  L_gi = 0.0
  for _t1576 in range(max(0, int(v_max_wgrains))):
    L_gb = (v_wg_mem + (L_gi * v_wg_stride))
    _t1577 = _ix(L_gb + 2.0)
    _t1578 = 0.0
    _mset(_t1577, _t1578)
    L_gi = (L_gi + 1.0)
  v_wg_timer = 1000000000.0
  v_wg_prev_ok = 0.0
  return v_wg_prev_ok

def f_sync_eval():
  global v_length, v_loop_width, v_rate_t, v_sync_a, v_sync_b
  L_a = 0.0
  L_b = 0.0
  L_ratio = 0.0
  L_best_err = 0.0
  L_err = 0.0
  v_sync_a = 0.0
  v_sync_b = 0.0
  L_best_err = 1000000.0
  _t1580 = 1.0 if _tr((1.0 if v_rate_t > 0.0001 else 0.0)) else 0.0
  if _t1580:
    _t1580 = 1.0 if _tr((1.0 if v_loop_width > 0.0 else 0.0)) else 0.0
  _t1579 = 1.0 if _tr(_t1580) else 0.0
  if _t1579:
    _t1579 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
  if _tr(_t1579):
    L_b = 1.0
    _t1582 = 0
    while True:
      if not _tr((1.0 if L_b <= 16.0 else 0.0)): break
      L_a = 1.0
      _t1583 = 0
      while True:
        if not _tr((1.0 if L_a <= 16.0 else 0.0)): break
        _t1584 = ((L_b * v_loop_width) - ((L_a * v_length) * v_rate_t))
        _t1585 = abs(_t1584)
        L_err = _t1585
        _t1586 = 1.0 if _tr((1.0 if L_err < 8.0 else 0.0)) else 0.0
        if _t1586:
          _t1586 = 1.0 if _tr((1.0 if L_err < L_best_err else 0.0)) else 0.0
        if _tr(_t1586):
          L_best_err = L_err
          v_sync_a = L_a
          v_sync_b = L_b
          _t1587 = v_sync_b
        else:
          _t1587 = 0.0
        L_a = (L_a + 1.0)
        _t1583 += 1
        if _t1583 > 1000000: break
      L_b = (L_b + 1.0)
      _t1582 += 1
      if _t1582 > 1000000: break
    if _tr((1.0 if L_best_err >= 12.0 else 0.0)):
      v_sync_a = 0.0
      v_sync_b = 0.0
      _t1588 = v_sync_b
    else:
      _t1588 = 0.0
    _t1581 = _t1588
  else:
    _t1581 = 0.0
  return _t1581

def f_sync_expected():
  global v_clk_cyc, v_length, v_loop_start, v_loop_width, v_master_pos, v_ping_pong_dir, v_pingpong_on, v_rate_t, v_rev_on, v_sync_a
  L_e = 0.0
  L_o = 0.0
  L_w = 0.0
  L_sa = 0.0
  L_is_rev = 0.0
  _t1589 = v_loop_width
  _t1590 = max(_t1589, 1.0)
  L_w = _t1590
  _t1591 = v_sync_a
  _t1592 = max(_t1591, 1.0)
  L_sa = _t1592
  L_e = ((_mod(v_clk_cyc, L_sa) * v_length) + v_master_pos)
  L_o = (L_e * v_rate_t)
  _t1593 = _div(L_o, L_w)
  _t1594 = _floor(_t1593)
  L_o = (L_o - (_t1594 * L_w))
  _t1596 = v_rev_on
  _t1595 = 1.0 if _tr(v_pingpong_on) else 0.0
  if _t1595:
    _t1595 = 1.0 if _tr((1.0 if v_ping_pong_dir < 0.0 else 0.0)) else 0.0
  L_is_rev = (0.0 if abs(_t1596 - _t1595) < 0.00001 else 1.0)
  if _tr(L_is_rev):
    _t1598 = v_loop_start
    _t1601 = (v_loop_start + L_w)
    _t1599 = L_o
    _t1600 = max(_t1599, 0.0001)
    _t1602 = ((_t1601 - _t1600) - 1.0)
    _t1603 = max(_t1598, _t1602)
    _t1597 = _t1603
  else:
    _t1607 = v_loop_start
    _t1604 = L_o
    _t1605 = (L_w - 0.0001)
    _t1606 = min(_t1604, _t1605)
    _t1597 = (_t1607 + _t1606)
  return _t1597

def f_sync_expected_win(L_ws, L_ww):
  global v_clk_cyc, v_length, v_master_pos, v_ping_pong_dir, v_pingpong_on, v_rate_t, v_rev_on, v_sync_a
  L_e = 0.0
  L_o = 0.0
  L_w = 0.0
  L_sa = 0.0
  L_is_rev = 0.0
  _t1608 = L_ww
  _t1609 = max(_t1608, 1.0)
  L_w = _t1609
  _t1610 = v_sync_a
  _t1611 = max(_t1610, 1.0)
  L_sa = _t1611
  L_e = ((_mod(v_clk_cyc, L_sa) * v_length) + v_master_pos)
  L_o = (L_e * v_rate_t)
  _t1612 = _div(L_o, L_w)
  _t1613 = _floor(_t1612)
  L_o = (L_o - (_t1613 * L_w))
  _t1615 = v_rev_on
  _t1614 = 1.0 if _tr(v_pingpong_on) else 0.0
  if _t1614:
    _t1614 = 1.0 if _tr((1.0 if v_ping_pong_dir < 0.0 else 0.0)) else 0.0
  L_is_rev = (0.0 if abs(_t1615 - _t1614) < 0.00001 else 1.0)
  if _tr(L_is_rev):
    _t1617 = L_ws
    _t1620 = (L_ws + L_w)
    _t1618 = L_o
    _t1619 = max(_t1618, 0.0001)
    _t1621 = ((_t1620 - _t1619) - 1.0)
    _t1622 = max(_t1617, _t1621)
    _t1616 = _t1622
  else:
    _t1626 = L_ws
    _t1623 = L_o
    _t1624 = (L_w - 0.0001)
    _t1625 = min(_t1623, _t1624)
    _t1616 = (_t1626 + _t1625)
  return _t1616

def f_bg_sync_ok():
  global v_pingpong_on, v_state, v_sync_a, v_sync_b
  _t1628 = 1.0 if _tr((1.0 if v_sync_a > 0.0 else 0.0)) else 0.0
  if _t1628:
    _t1629 = 1.0 if _tr((1.0 if abs(v_sync_a - 1.0) < 0.00001 else 0.0)) else 0.0
    if not _t1629:
      _t1629 = 1.0 if _tr((0.0 if _tr(v_pingpong_on) else 1.0)) else 0.0
    _t1628 = 1.0 if _tr(_t1629) else 0.0
  _t1627 = 1.0 if _tr(_t1628) else 0.0
  if _t1627:
    _t1630 = 1.0 if _tr((0.0 if abs(v_state - 6.0) < 0.00001 else 1.0)) else 0.0
    if not _t1630:
      _t1631 = 1.0 if _tr((1.0 if abs(v_sync_a - 1.0) < 0.00001 else 0.0)) else 0.0
      if _t1631:
        _t1631 = 1.0 if _tr((1.0 if abs(v_sync_b - 1.0) < 0.00001 else 0.0)) else 0.0
      _t1630 = 1.0 if _tr(_t1631) else 0.0
    _t1627 = 1.0 if _tr(_t1630) else 0.0
  return _t1627

def f_trigger_restart():
  global v_eff_end, v_eff_start, v_length, v_one_shot_playing, v_one_shot_pp_state, v_ping_pong_dir, v_rev_on, v_target_p
  if _tr((1.0 if v_length > 0.0 else 0.0)):
    v_one_shot_playing = 1.0
    v_one_shot_pp_state = 0.0
    v_ping_pong_dir = 1.0
    if _tr(v_rev_on):
      _t1633 = (v_eff_end - 0.0001)
    else:
      _t1633 = v_eff_start
    v_target_p = _t1633
    _t1634 = v_target_p
    _t1635 = f_trigger_pos_jump(_t1634)
    _t1632 = _t1635
  else:
    _t1632 = 0.0
  return _t1632

def f_slicer_regen():
  global v_last_slicer_mode, v_slicer_current_step, v_slicer_mode
  L_sl_len = 0.0
  _t1636 = f_get_slicer_len()
  L_sl_len = _t1636
  _t1637 = L_sl_len
  _t1638 = f_generate_slicer_sequence(_t1637)
  v_slicer_current_step = 0.0
  v_last_slicer_mode = v_slicer_mode
  return v_last_slicer_mode

def f_trans_cap(L_maxn):
  global v_trans_count, v_trans_mem, v_trans_str
  L_i = 0.0
  L_w = 0.0
  L_wi = 0.0
  L_j = 0.0
  _t1639 = 1.0 if _tr((1.0 if L_maxn >= 2.0 else 0.0)) else 0.0
  if _t1639:
    _t1639 = 1.0 if _tr((1.0 if v_trans_count > L_maxn else 0.0)) else 0.0
  if _tr(_t1639):
    _t1641 = 0
    while True:
      if not _tr((1.0 if v_trans_count > L_maxn else 0.0)): break
      L_w = 1000000.0
      L_wi = 0.0
      L_i = 0.0
      _t1642 = 0
      while True:
        if not _tr((1.0 if L_i < v_trans_count else 0.0)): break
        if _tr((1.0 if _mget(v_trans_str + L_i) < L_w else 0.0)):
          L_w = _mget(v_trans_str + L_i)
          L_wi = L_i
          _t1643 = L_wi
        else:
          _t1643 = 0.0
        L_i = (L_i + 1.0)
        _t1642 += 1
        if _t1642 > 1000000: break
      L_j = L_wi
      _t1644 = 0
      while True:
        if not _tr((1.0 if L_j < (v_trans_count - 1.0) else 0.0)): break
        _t1645 = _ix(v_trans_mem + L_j)
        _t1646 = _mget(v_trans_mem + (L_j + 1.0))
        _mset(_t1645, _t1646)
        _t1647 = _ix(v_trans_str + L_j)
        _t1648 = _mget(v_trans_str + (L_j + 1.0))
        _mset(_t1647, _t1648)
        L_j = (L_j + 1.0)
        _t1644 += 1
        if _t1644 > 1000000: break
      v_trans_count = (v_trans_count - 1.0)
      _t1641 += 1
      if _t1641 > 1000000: break
    _t1640 = 0.0
  else:
    _t1640 = 0.0
  return _t1640

def f_an_fractions(L_m):
  global v_ana_mode, v_loop_start, v_loop_width, v_max_transients, v_sel_k, v_sel_n, v_sel_s
  L_i = 0.0
  _t1649 = v_max_transients
  _t1650 = L_m
  _t1651 = _floor(_t1650)
  _t1652 = _t1651
  _t1653 = min(_t1649, _t1652)
  _t1654 = _t1653
  _t1655 = max(1.0, _t1654)
  L_m = _t1655
  L_i = 0.0
  for _t1656 in range(max(0, int(L_m))):
    _t1657 = _ix(v_sel_k + L_i)
    _t1658 = (v_loop_start + _div((L_i * v_loop_width), L_m))
    _t1659 = _floor(_t1658)
    _t1660 = _t1659
    _mset(_t1657, _t1660)
    _t1661 = _ix(v_sel_s + L_i)
    _t1662 = 0.5
    _mset(_t1661, _t1662)
    L_i = (L_i + 1.0)
  v_sel_n = L_m
  v_ana_mode = 1.0
  return v_ana_mode

def f_an_sortfill():
  global v_an_n, v_det_strict, v_loop_start, v_loop_width, v_max_transients, v_sel_k, v_sel_n, v_sel_s, v_srate
  L_i = 0.0
  L_j = 0.0
  L_tk = 0.0
  L_ts = 0.0
  L_bi = 0.0
  L_bg = 0.0
  L_g = 0.0
  L_prev = 0.0
  L_nxt = 0.0
  L_i = 1.0
  _t1663 = 0
  while True:
    if not _tr((1.0 if L_i < v_sel_n else 0.0)): break
    L_tk = _mget(v_sel_k + L_i)
    L_ts = _mget(v_sel_s + L_i)
    L_j = (L_i - 1.0)
    _t1664 = 0
    while True:
      _t1665 = 1.0 if _tr((1.0 if L_j >= 0.0 else 0.0)) else 0.0
      if _t1665:
        _t1665 = 1.0 if _tr((1.0 if _mget(v_sel_k + L_j) > L_tk else 0.0)) else 0.0
      if not _tr(_t1665): break
      _t1666 = _ix(v_sel_k + (L_j + 1.0))
      _t1667 = _mget(v_sel_k + L_j)
      _mset(_t1666, _t1667)
      _t1668 = _ix(v_sel_s + (L_j + 1.0))
      _t1669 = _mget(v_sel_s + L_j)
      _mset(_t1668, _t1669)
      L_j = (L_j - 1.0)
      _t1664 += 1
      if _t1664 > 1000000: break
    _t1670 = _ix(v_sel_k + (L_j + 1.0))
    _t1671 = L_tk
    _mset(_t1670, _t1671)
    _t1672 = _ix(v_sel_s + (L_j + 1.0))
    _t1673 = L_ts
    _mset(_t1672, _t1673)
    L_i = (L_i + 1.0)
    _t1663 += 1
    if _t1663 > 1000000: break
  _t1674 = 1.0 if _tr((1.0 if v_an_n >= 1.0 else 0.0)) else 0.0
  if _t1674:
    _t1674 = 1.0 if _tr((0.0 if _tr(v_det_strict) else 1.0)) else 0.0
  if _tr(_t1674):
    L_nxt = 1.0
    _t1676 = 0
    while True:
      _t1677 = 1.0 if _tr(L_nxt) else 0.0
      if _t1677:
        _t1681 = v_sel_n
        _t1678 = v_an_n
        _t1679 = v_max_transients
        _t1680 = min(_t1678, _t1679)
        _t1677 = 1.0 if _tr((1.0 if _t1681 < _t1680 else 0.0)) else 0.0
      if not _tr(_t1677): break
      L_bg = 0.0
      L_bi = (-1.0)
      L_i = 0.0
      _t1682 = 0
      while True:
        if not _tr((1.0 if L_i <= v_sel_n else 0.0)): break
        if _tr((1.0 if abs(L_i - 0.0) < 0.00001 else 0.0)):
          _t1683 = v_loop_start
        else:
          _t1683 = _mget(v_sel_k + (L_i - 1.0))
        L_prev = _t1683
        if _tr((1.0 if abs(L_i - v_sel_n) < 0.00001 else 0.0)):
          _t1684 = (v_loop_start + v_loop_width)
        else:
          _t1684 = _mget(v_sel_k + L_i)
        L_g = (_t1684 - L_prev)
        if _tr((1.0 if L_g > L_bg else 0.0)):
          L_bg = L_g
          L_bi = L_i
          _t1685 = L_bi
        else:
          _t1685 = 0.0
        L_i = (L_i + 1.0)
        _t1682 += 1
        if _t1682 > 1000000: break
      _t1686 = 1.0 if _tr((1.0 if L_bi < 0.0 else 0.0)) else 0.0
      if not _t1686:
        _t1686 = 1.0 if _tr((1.0 if L_bg < (v_srate * 0.08) else 0.0)) else 0.0
      if _tr(_t1686):
        L_nxt = 0.0
        _t1687 = L_nxt
      else:
        if _tr((1.0 if abs(L_bi - 0.0) < 0.00001 else 0.0)):
          _t1688 = v_loop_start
        else:
          _t1688 = _mget(v_sel_k + (L_bi - 1.0))
        L_prev = _t1688
        L_j = v_sel_n
        _t1689 = 0
        while True:
          if not _tr((1.0 if L_j > L_bi else 0.0)): break
          _t1690 = _ix(v_sel_k + L_j)
          _t1691 = _mget(v_sel_k + (L_j - 1.0))
          _mset(_t1690, _t1691)
          _t1692 = _ix(v_sel_s + L_j)
          _t1693 = _mget(v_sel_s + (L_j - 1.0))
          _mset(_t1692, _t1693)
          L_j = (L_j - 1.0)
          _t1689 += 1
          if _t1689 > 1000000: break
        _t1694 = _ix(v_sel_k + L_bi)
        _t1695 = (L_prev + (L_bg * 0.5))
        _t1696 = _floor(_t1695)
        _t1697 = _t1696
        _mset(_t1694, _t1697)
        _t1698 = _ix(v_sel_s + L_bi)
        _t1699 = 0.0
        _mset(_t1698, _t1699)
        v_sel_n = (v_sel_n + 1.0)
        _t1687 = v_sel_n
      _t1676 += 1
      if _t1676 > 1000000: break
    _t1675 = 0.0
  else:
    _t1675 = 0.0
  return _t1675

def f_an_commit():
  global v_an_keep, v_analysing, v_det_strict, v_max_slices, v_sel_k, v_sel_n, v_sel_s, v_slicer_steps, v_step_len, v_trans_count, v_trans_mem, v_trans_str
  L_i = 0.0
  L_ch = 0.0
  _t1700 = 1.0 if _tr((1.0 if v_sel_n < 1.0 else 0.0)) else 0.0
  if _t1700:
    _t1700 = 1.0 if _tr((0.0 if _tr(v_det_strict) else 1.0)) else 0.0
  if _tr(_t1700):
    if _tr((1.0 if v_max_slices >= 1.0 else 0.0)):
      _t1702 = v_max_slices
    else:
      _t1703 = (v_slicer_steps + 0.5)
      _t1704 = _floor(_t1703)
      _t1705 = _t1704
      _t1706 = max(2.0, _t1705)
      _t1702 = _t1706
    _t1707 = _t1702
    _t1708 = f_an_fractions(_t1707)
    _t1701 = _t1708
  else:
    _t1701 = 0.0
  L_ch = (0.0 if abs(v_sel_n - v_trans_count) < 0.00001 else 1.0)
  L_i = 0.0
  for _t1709 in range(max(0, int(v_sel_n))):
    _t1710 = (_mget(v_sel_k + L_i) - _mget(v_trans_mem + L_i))
    _t1711 = abs(_t1710)
    if _tr((1.0 if _t1711 > 2.0 else 0.0)):
      L_ch = 1.0
      _t1712 = L_ch
    else:
      _t1712 = 0.0
    L_i = (L_i + 1.0)
  L_i = 0.0
  for _t1713 in range(max(0, int(v_sel_n))):
    _t1714 = _ix(v_trans_mem + L_i)
    _t1715 = _mget(v_sel_k + L_i)
    _mset(_t1714, _t1715)
    _t1716 = _ix(v_trans_str + L_i)
    _t1717 = _mget(v_sel_s + L_i)
    _mset(_t1716, _t1717)
    L_i = (L_i + 1.0)
  v_trans_count = v_sel_n
  _t1718 = 1.0 if _tr(L_ch) else 0.0
  if not _t1718:
    _t1718 = 1.0 if _tr((0.0 if _tr(v_an_keep) else 1.0)) else 0.0
  if _tr(_t1718):
    _t1720 = f_get_slicer_len()
    v_step_len = _t1720
    _t1721 = v_step_len
    _t1722 = f_generate_slicer_sequence(_t1721)
    _t1719 = _t1722
  else:
    _t1719 = 0.0
  v_an_keep = 0.0
  v_analysing = 0.0
  return v_analysing

def f_slicer_fill(L_a, L_b):
  global v_seq_mem, v_trans_count, v_trans_mem
  L_i = 0.0
  if _tr((1.0 if v_trans_count > 0.0 else 0.0)):
    L_i = L_a
    _t1724 = 0
    while True:
      if not _tr((1.0 if L_i < L_b else 0.0)): break
      _t1725 = _ix(v_seq_mem + L_i)
      _t1726 = v_trans_count
      _t1727 = _rand(_t1726)
      _t1728 = _t1727
      _t1729 = _floor(_t1728)
      _t1730 = _mget(v_trans_mem + _t1729)
      _mset(_t1725, _t1730)
      L_i = (L_i + 1.0)
      _t1724 += 1
      if _t1724 > 1000000: break
    _t1723 = 0.0
  else:
    _t1723 = 0.0
  return _t1723

def f_slicer_resize(L_old_n, L_new_n):
  global v_slice_pitch_mem, v_slicer_pitch_spread
  L_i = 0.0
  if _tr((1.0 if L_new_n > L_old_n else 0.0)):
    _t1732 = L_old_n
    _t1733 = L_new_n
    _t1734 = f_slicer_fill(_t1732, _t1733)
    if _tr((1.0 if v_slicer_pitch_spread > 0.0001 else 0.0)):
      _t1736 = L_new_n
      _t1737 = f_update_slicer_pitches(_t1736)
      _t1735 = _t1737
    else:
      L_i = L_old_n
      _t1738 = 0
      while True:
        if not _tr((1.0 if L_i < L_new_n else 0.0)): break
        _t1739 = _ix(v_slice_pitch_mem + L_i)
        _t1740 = 0.0
        _mset(_t1739, _t1740)
        L_i = (L_i + 1.0)
        _t1738 += 1
        if _t1738 > 1000000: break
      _t1735 = 0.0
    _t1731 = _t1735
  else:
    _t1731 = 0.0
  return _t1731

def f_preset_store(L_k):
  global v_max_transients, v_preset_mem, v_pslot, v_seq_mem, v_slice_pitch_mem, v_slicer_mode, v_slicer_steps
  L_pm = 0.0
  L_n = 0.0
  L_pm = (v_preset_mem + (L_k * v_pslot))
  _t1741 = f_get_slicer_len()
  _t1742 = _t1741
  _t1743 = v_max_transients
  _t1744 = min(_t1742, _t1743)
  L_n = _t1744
  _t1745 = _ix(L_pm + 0.0)
  _t1746 = 1.0
  _mset(_t1745, _t1746)
  _t1747 = _ix(L_pm + 1.0)
  _t1748 = L_n
  _mset(_t1747, _t1748)
  _t1749 = _ix(L_pm + 2.0)
  _t1750 = v_slicer_mode
  _mset(_t1749, _t1750)
  _t1751 = _ix(L_pm + 3.0)
  _t1752 = v_slicer_steps
  _mset(_t1751, _t1752)
  _t1753 = (L_pm + 4.0)
  _t1754 = v_seq_mem
  _t1755 = L_n
  _t1756 = _memcpy(_t1753, _t1754, _t1755)
  _t1757 = ((L_pm + 4.0) + v_max_transients)
  _t1758 = v_slice_pitch_mem
  _t1759 = L_n
  _t1760 = _memcpy(_t1757, _t1758, _t1759)
  return _t1760

def f_preset_load(L_k):
  global v_last_slicer_mode, v_last_steps, v_max_transients, v_preset_mem, v_pslot, v_seq_mem, v_slice_pitch_mem, v_slicer_mode, v_slicer_steps
  L_pm = 0.0
  L_n = 0.0
  L_ln = 0.0
  L_pm = (v_preset_mem + (L_k * v_pslot))
  L_n = _mget(L_pm + 1.0)
  v_slicer_mode = _mget(L_pm + 2.0)
  v_slicer_mode = v_slicer_mode
  v_slicer_steps = _mget(L_pm + 3.0)
  v_slicer_steps = v_slicer_steps
  _t1761 = v_seq_mem
  _t1762 = (L_pm + 4.0)
  _t1763 = L_n
  _t1764 = _memcpy(_t1761, _t1762, _t1763)
  _t1765 = v_slice_pitch_mem
  _t1766 = ((L_pm + 4.0) + v_max_transients)
  _t1767 = L_n
  _t1768 = _memcpy(_t1765, _t1766, _t1767)
  _t1769 = f_get_slicer_len()
  L_ln = _t1769
  if _tr((1.0 if L_ln > L_n else 0.0)):
    _t1771 = L_n
    _t1772 = L_ln
    _t1773 = f_slicer_resize(_t1771, _t1772)
    _t1770 = _t1773
  else:
    _t1770 = 0.0
  v_last_slicer_mode = v_slicer_mode
  v_last_steps = v_slicer_steps
  return v_last_steps

def f_preset_switch(L_k):
  global v_preset_cur, v_preset_mem, v_pslot
  L_pm = 0.0
  if _tr((1.0 if v_preset_cur >= 0.0 else 0.0)):
    _t1775 = v_preset_cur
    _t1776 = f_preset_store(_t1775)
    _t1774 = _t1776
  else:
    _t1774 = 0.0
  v_preset_cur = L_k
  L_pm = (v_preset_mem + (L_k * v_pslot))
  if _tr(_mget(L_pm + 0.0)):
    _t1778 = L_k
    _t1779 = f_preset_load(_t1778)
    _t1777 = _t1779
  else:
    _t1780 = L_k
    _t1781 = f_preset_store(_t1780)
    _t1777 = _t1781
  return _t1777

def f_multiply_extend():
  global v_active_history_idx, v_an_mx_was, v_an_wrap_pending, v_analysing, v_base_backup_l, v_base_backup_r, v_dirty_len, v_eff_end, v_eff_len, v_eff_start, v_hist_len, v_left_buf, v_length, v_loop_start, v_loop_width, v_max_transients, v_mult_len, v_right_buf, v_slicer_mode, v_smooth_start, v_smooth_width, v_sync_hard_resync, v_trans_count, v_trans_mem, v_trans_str
  L_old_len = 0.0
  L_n = 0.0
  L_t = 0.0
  L_old_len = v_length
  _t1782 = (v_left_buf + L_old_len)
  _t1783 = v_base_backup_l
  _t1784 = v_mult_len
  _t1785 = _memcpy(_t1782, _t1783, _t1784)
  _t1786 = (v_right_buf + L_old_len)
  _t1787 = v_base_backup_r
  _t1788 = v_mult_len
  _t1789 = _memcpy(_t1786, _t1787, _t1788)
  v_length = (L_old_len + v_mult_len)
  _t1790 = v_dirty_len
  _t1791 = v_length
  _t1792 = max(_t1790, _t1791)
  v_dirty_len = _t1792
  _t1793 = _ix(v_hist_len + v_active_history_idx)
  _t1794 = v_length
  _mset(_t1793, _t1794)
  v_loop_start = 0.0
  v_loop_width = v_length
  v_smooth_start = 0.0
  v_smooth_width = v_length
  v_eff_start = 0.0
  v_eff_end = v_length
  _t1795 = v_length
  _t1796 = max(_t1795, 16.0)
  v_eff_len = _t1796
  v_an_mx_was = v_analysing
  v_analysing = 0.0
  if _tr((1.0 if abs(v_an_mx_was - 0.0) < 0.00001 else 0.0)):
    L_n = v_trans_count
    L_t = 0.0
    for _t1798 in range(max(0, int(L_n))):
      _t1799 = 1.0 if _tr((1.0 if _mget(v_trans_mem + L_t) < v_mult_len else 0.0)) else 0.0
      if _t1799:
        _t1799 = 1.0 if _tr((1.0 if v_trans_count < v_max_transients else 0.0)) else 0.0
      if _tr(_t1799):
        _t1801 = _ix(v_trans_mem + v_trans_count)
        _t1802 = (_mget(v_trans_mem + L_t) + L_old_len)
        _mset(_t1801, _t1802)
        _t1803 = _ix(v_trans_str + v_trans_count)
        _t1804 = _mget(v_trans_str + L_t)
        _mset(_t1803, _t1804)
        v_trans_count = (v_trans_count + 1.0)
        _t1800 = v_trans_count
      else:
        _t1800 = 0.0
      L_t = (L_t + 1.0)
    if _tr((1.0 if abs(v_slicer_mode - 5.0) < 0.00001 else 0.0)):
      _t1806 = f_slicer_regen()
      _t1805 = _t1806
    else:
      _t1805 = 0.0
    _t1797 = _t1805
  else:
    _t1797 = 0.0
  v_an_wrap_pending = 1.0
  v_sync_hard_resync = 1.0
  return v_sync_hard_resync

def f_reset_all_params():
  global v_auto_on, v_br_mix, v_clk_src, v_cloud_chaos, v_cloud_density, v_cloud_diffuse, v_cloud_freeze, v_cloud_lfo_depth, v_cloud_lfo_rate, v_cloud_lfo_shape, v_cloud_mix, v_cloud_on, v_cloud_pitch_spread, v_cloud_pos_mode, v_cloud_pos_pct, v_cloud_size, v_cloud_spread, v_degradation, v_dens_len, v_dens_occ, v_det_hold_ms, v_det_thresh, v_dub_align_ms, v_dub_grain_ms, v_fade_ms, v_feedback, v_grain_fade, v_grain_ms, v_grid_sub, v_last_det_h, v_last_det_t, v_last_pitch_spread, v_length, v_link_on, v_loop_beats, v_loop_quant, v_loop_start, v_loop_width, v_max_slices, v_mix, v_out_vol, v_pingpong_on, v_pitch, v_play_mode, v_read_align_ms, v_rev_on, v_sampler_pitch_mode, v_sampler_release, v_sampler_root, v_slice_attack_ms, v_slice_decay_ms, v_slice_decay_pos, v_slicer_link, v_slicer_mode, v_slicer_pitch_spread, v_slicer_preset, v_slicer_src, v_slicer_steps, v_slicer_sub, v_slx_mix, v_speed, v_src_auto, v_stereo_width, v_sync_hard_resync, v_trans_hold_ms, v_trans_sens, v_wg_fade
  v_speed = 1.0
  v_speed = v_speed
  v_pitch = 0.0
  v_pitch = v_pitch
  v_mix = 1.0
  v_mix = v_mix
  v_grain_ms = 80.0
  v_grain_ms = v_grain_ms
  v_fade_ms = 10.0
  v_fade_ms = v_fade_ms
  v_play_mode = 0.0
  v_play_mode = v_play_mode
  v_link_on = 0.0
  v_link_on = v_link_on
  v_trans_sens = 0.15
  v_trans_sens = v_trans_sens
  v_trans_hold_ms = 120.0
  v_trans_hold_ms = v_trans_hold_ms
  v_grain_fade = 25.0
  v_grain_fade = v_grain_fade
  v_wg_fade = 0.25
  _t1807 = 1.0 if _tr((0.0 if abs(v_slicer_mode - 5.0) < 0.00001 else 1.0)) else 0.0
  if not _t1807:
    _t1807 = 1.0 if _tr((0.0 if abs(v_slicer_sub - 3.0) < 0.00001 else 1.0)) else 0.0
  if _tr(_t1807):
    v_slicer_mode = 5.0
    v_slicer_mode = 5.0
    v_slicer_sub = 3.0
    v_slicer_sub = 3.0
    _t1809 = f_slicer_regen()
    _t1808 = _t1809
  else:
    _t1808 = 0.0
  v_slice_decay_ms = 150.0
  v_slice_decay_pos = 75.0
  v_slice_decay_pos = v_slice_decay_pos
  v_slice_attack_ms = 0.0
  v_slice_attack_ms = v_slice_attack_ms
  v_rev_on = 0.0
  v_rev_on = v_rev_on
  v_pingpong_on = 0.0
  v_pingpong_on = v_pingpong_on
  v_feedback = 1.0
  v_feedback = v_feedback
  v_degradation = 1.0
  v_degradation = v_degradation
  v_stereo_width = 0.0
  v_stereo_width = v_stereo_width
  v_br_mix = 1.0
  v_br_mix = v_br_mix
  v_slx_mix = 1.0
  v_slx_mix = v_slx_mix
  v_cloud_on = 0.0
  v_cloud_on = v_cloud_on
  v_loop_quant = 0.0
  v_loop_quant = v_loop_quant
  v_cloud_density = 0.5
  v_cloud_density = v_cloud_density
  v_cloud_chaos = 0.0
  v_cloud_chaos = v_cloud_chaos
  v_cloud_spread = 0.1
  v_cloud_spread = v_cloud_spread
  v_dens_occ = 100.0
  v_dens_occ = v_dens_occ
  v_dens_len = 2.0
  v_dens_len = v_dens_len
  v_loop_beats = 0.0
  v_loop_beats = v_loop_beats
  v_slicer_src = 0.0
  v_slicer_src = v_slicer_src
  v_src_auto = 1.0
  v_src_auto = 1.0
  v_slicer_link = 0.0
  v_slicer_link = 0.0
  v_grid_sub = 3.0
  v_grid_sub = v_grid_sub
  v_slicer_pitch_spread = 0.0
  v_slicer_pitch_spread = v_slicer_pitch_spread
  v_last_pitch_spread = v_slicer_pitch_spread
  _t1810 = f_get_slicer_len()
  _t1811 = _t1810
  _t1812 = f_update_slicer_pitches(_t1811)
  v_cloud_pitch_spread = 0.0
  v_cloud_pitch_spread = v_cloud_pitch_spread
  v_cloud_mix = 1.0
  v_cloud_mix = v_cloud_mix
  v_cloud_pos_mode = 1.0
  v_cloud_pos_mode = v_cloud_pos_mode
  v_cloud_pos_pct = 50.0
  v_cloud_pos_pct = v_cloud_pos_pct
  v_cloud_lfo_shape = 0.0
  v_cloud_lfo_shape = v_cloud_lfo_shape
  v_cloud_lfo_rate = 1.0
  v_cloud_lfo_rate = v_cloud_lfo_rate
  v_cloud_lfo_depth = 0.0
  v_cloud_lfo_depth = v_cloud_lfo_depth
  v_cloud_size = 80.0
  v_cloud_size = v_cloud_size
  v_cloud_freeze = 0.0
  v_cloud_freeze = v_cloud_freeze
  v_cloud_diffuse = 0.0
  v_cloud_diffuse = v_cloud_diffuse
  v_sampler_root = 48.0
  v_sampler_root = v_sampler_root
  v_sampler_pitch_mode = 0.0
  v_sampler_pitch_mode = v_sampler_pitch_mode
  v_sampler_release = 0.0
  v_sampler_release = v_sampler_release
  v_clk_src = 0.0
  v_clk_src = v_clk_src
  v_slicer_steps = 8.0
  v_slicer_steps = v_slicer_steps
  v_max_slices = 16.0
  v_max_slices = v_max_slices
  v_slicer_preset = 1.0
  v_slicer_preset = v_slicer_preset
  v_dub_grain_ms = 25.0
  v_dub_grain_ms = v_dub_grain_ms
  v_dub_align_ms = 6.0
  v_dub_align_ms = v_dub_align_ms
  v_read_align_ms = 6.0
  v_read_align_ms = v_read_align_ms
  if _tr((1.0 if v_length <= 0.0 else 0.0)):
    v_out_vol = 1.0
    v_out_vol = v_out_vol
    _t1813 = v_out_vol
  else:
    _t1813 = 0.0
  v_auto_on = 0.0
  _t1814 = 1.0 if _tr((0.0 if abs(v_det_thresh - 0.01) < 0.00001 else 1.0)) else 0.0
  if not _t1814:
    _t1814 = 1.0 if _tr((0.0 if abs(v_det_hold_ms - 120.0) < 0.00001 else 1.0)) else 0.0
  if _tr(_t1814):
    v_det_thresh = 0.01
    v_det_thresh = v_det_thresh
    v_det_hold_ms = 120.0
    v_det_hold_ms = v_det_hold_ms
    v_last_det_t = v_det_thresh
    v_last_det_h = v_det_hold_ms
    _t1816 = f_start_analysis()
    _t1815 = _t1816
  else:
    _t1815 = 0.0
  if _tr((1.0 if v_length > 0.0 else 0.0)):
    v_loop_start = 0.0
    v_loop_width = v_length
    v_sync_hard_resync = 1.0
    _t1817 = v_sync_hard_resync
  else:
    _t1817 = 0.0
  return _t1817

def f_do_clear(L_clear_type):
  global v_active_history_idx, v_active_part, v_analysing, v_auto_on, v_base_len_part1, v_base_len_part2, v_base_len_part3, v_base_loop_length, v_buf_part1_l, v_buf_part1_r, v_buf_part2_l, v_buf_part2_r, v_buf_part3_l, v_buf_part3_r, v_clk_cyc, v_cloud_chaos, v_cloud_density, v_cloud_lfo_depth, v_cloud_lfo_rate, v_cloud_lfo_shape, v_cloud_mix, v_cloud_on, v_cloud_pitch_spread, v_cloud_pos_mode, v_cloud_pos_pct, v_cloud_spread, v_dens_occ, v_dirty_len, v_fade_ms, v_feedback, v_frz_copying, v_frz_prev, v_frz_ready, v_gmem, v_grain_fade, v_grain_ms, v_hist_len, v_hist_redo, v_hist_undo, v_history_count, v_history_head, v_i, v_idx_clr, v_instance_alias, v_instance_id, v_last_state_target, v_left_buf, v_len_part1, v_len_part2, v_len_part3, v_length, v_loop_beats, v_loop_quant, v_loop_start, v_loop_width, v_master_pos, v_master_pos1, v_master_pos2, v_master_pos3, v_max_history, v_one_shot_playing, v_out_vol, v_part_cloud_on, v_part_link_on, v_part_pingpong, v_part_pitch, v_part_play_mode, v_part_rev, v_part_speed, v_pending_part_switch, v_pingpong_on, v_pitch, v_play_mode, v_pos, v_rd_valid, v_rec_ref_kind, v_rev_on, v_right_buf, v_rp_tail_on, v_single_buf_len, v_slicer_pitch_spread, v_speed, v_state, v_state_target, v_state_transition_fade, v_sync_hard_resync, v_target_part, v_trans_count, v_warp_on, v_wg_fade, v_wp_busy, v_wp_live, v_wp_phase, v_wp_scan, v_xarm, v_xf_on
  L_ms_off = 0.0
  L_wipe_n = 0.0
  L_wipe1 = 0.0
  L_wipe2 = 0.0
  L_wipe3 = 0.0
  L_hi = 0.0
  _t1818 = v_dirty_len
  _t1819 = v_length
  _t1820 = max(_t1818, _t1819)
  L_wipe_n = _t1820
  _t1821 = L_wipe_n
  _t1822 = max(_t1821, 0.0)
  _t1823 = _t1822
  _t1824 = v_single_buf_len
  _t1825 = min(_t1823, _t1824)
  L_wipe_n = _t1825
  _t1826 = v_len_part1
  _t1827 = max(_t1826, 0.0)
  _t1828 = _t1827
  _t1829 = v_single_buf_len
  _t1830 = min(_t1828, _t1829)
  L_wipe1 = _t1830
  _t1831 = v_len_part2
  _t1832 = max(_t1831, 0.0)
  _t1833 = _t1832
  _t1834 = v_single_buf_len
  _t1835 = min(_t1833, _t1834)
  L_wipe2 = _t1835
  _t1836 = v_len_part3
  _t1837 = max(_t1836, 0.0)
  _t1838 = _t1837
  _t1839 = v_single_buf_len
  _t1840 = min(_t1838, _t1839)
  L_wipe3 = _t1840
  L_hi = 0.0
  for _t1841 in range(max(0, int(v_max_history))):
    _t1842 = L_wipe_n
    _t1843 = _mget(v_hist_len + L_hi)
    _t1844 = max(_t1843, 0.0)
    _t1845 = _t1844
    _t1846 = v_single_buf_len
    _t1847 = min(_t1845, _t1846)
    _t1848 = _t1847
    _t1849 = max(_t1842, _t1848)
    L_wipe_n = _t1849
    L_hi = (L_hi + 1.0)
  v_wp_busy = 0.0
  v_wp_phase = 0.0
  v_wp_live = 0.0
  v_wp_scan = 0.0
  v_warp_on = 0.0
  v_warp_on = 0.0
  _t1850 = f_dub_discard()
  v_out_vol = 1.0
  v_out_vol = v_out_vol
  v_feedback = 1.0
  v_feedback = v_feedback
  v_speed = 1.0
  v_speed = v_speed
  v_pitch = 0.0
  v_pitch = v_pitch
  v_rev_on = 0.0
  v_rev_on = v_rev_on
  v_pingpong_on = 0.0
  v_pingpong_on = v_pingpong_on
  v_grain_ms = 80.0
  v_grain_ms = v_grain_ms
  v_grain_fade = 25.0
  v_grain_fade = v_grain_fade
  v_wg_fade = 0.25
  v_fade_ms = 10.0
  v_fade_ms = v_fade_ms
  v_auto_on = 0.0
  v_cloud_on = 0.0
  v_cloud_on = v_cloud_on
  v_cloud_density = 0.5
  v_cloud_density = v_cloud_density
  v_cloud_chaos = 0.0
  v_cloud_chaos = v_cloud_chaos
  v_cloud_spread = 0.1
  v_cloud_spread = v_cloud_spread
  v_cloud_pitch_spread = 0.0
  v_cloud_pitch_spread = v_cloud_pitch_spread
  v_cloud_mix = 1.0
  v_cloud_mix = v_cloud_mix
  v_cloud_pos_mode = 1.0
  v_cloud_pos_mode = v_cloud_pos_mode
  v_cloud_pos_pct = 50.0
  v_cloud_pos_pct = v_cloud_pos_pct
  v_cloud_lfo_shape = 0.0
  v_cloud_lfo_shape = v_cloud_lfo_shape
  v_cloud_lfo_rate = 1.0
  v_cloud_lfo_rate = v_cloud_lfo_rate
  v_cloud_lfo_depth = 0.0
  v_cloud_lfo_depth = v_cloud_lfo_depth
  v_play_mode = 0.0
  v_play_mode = v_play_mode
  v_dens_occ = 100.0
  v_dens_occ = v_dens_occ
  v_loop_beats = 0.0
  v_loop_beats = v_loop_beats
  v_loop_quant = 0.0
  v_loop_quant = v_loop_quant
  v_slicer_pitch_spread = 0.0
  v_slicer_pitch_spread = v_slicer_pitch_spread
  v_state_target = 0.0
  v_pos = 0.0
  v_master_pos = 0.0
  v_clk_cyc = 0.0
  v_length = 0.0
  v_loop_start = 0.0
  v_loop_width = 0.0
  v_base_loop_length = 0.0
  v_trans_count = 0.0
  v_analysing = 0.0
  v_one_shot_playing = 0.0
  v_history_head = 0.0
  v_history_count = 1.0
  v_hist_undo = 0.0
  v_hist_redo = 0.0
  v_dirty_len = 0.0
  _t1851 = f_reset_all_params()
  if _tr((1.0 if L_wipe_n > 0.0 else 0.0)):
    _t1853 = v_left_buf
    _t1854 = L_wipe_n
    _t1855 = _memset(_t1853, 0.0, _t1854)
    _t1856 = v_right_buf
    _t1857 = L_wipe_n
    _t1858 = _memset(_t1856, 0.0, _t1857)
    _t1852 = _t1858
  else:
    _t1852 = 0.0
  if _tr((1.0 if L_wipe1 > 0.0 else 0.0)):
    _t1860 = v_buf_part1_l
    _t1861 = L_wipe1
    _t1862 = _memset(_t1860, 0.0, _t1861)
    _t1863 = v_buf_part1_r
    _t1864 = L_wipe1
    _t1865 = _memset(_t1863, 0.0, _t1864)
    _t1859 = _t1865
  else:
    _t1859 = 0.0
  if _tr((1.0 if abs(L_clear_type - 1.0) < 0.00001 else 0.0)):
    if _tr((1.0 if L_wipe2 > 0.0 else 0.0)):
      _t1868 = v_buf_part2_l
      _t1869 = L_wipe2
      _t1870 = _memset(_t1868, 0.0, _t1869)
      _t1871 = v_buf_part2_r
      _t1872 = L_wipe2
      _t1873 = _memset(_t1871, 0.0, _t1872)
      _t1867 = _t1873
    else:
      _t1867 = 0.0
    if _tr((1.0 if L_wipe3 > 0.0 else 0.0)):
      _t1875 = v_buf_part3_l
      _t1876 = L_wipe3
      _t1877 = _memset(_t1875, 0.0, _t1876)
      _t1878 = v_buf_part3_r
      _t1879 = L_wipe3
      _t1880 = _memset(_t1878, 0.0, _t1879)
      _t1874 = _t1880
    else:
      _t1874 = 0.0
    _t1866 = _t1874
  else:
    _t1881 = 1.0 if _tr((1.0 if abs(v_active_part - 2.0) < 0.00001 else 0.0)) else 0.0
    if _t1881:
      _t1881 = 1.0 if _tr((1.0 if L_wipe2 > 0.0 else 0.0)) else 0.0
    if _tr(_t1881):
      _t1883 = v_buf_part2_l
      _t1884 = L_wipe2
      _t1885 = _memset(_t1883, 0.0, _t1884)
      _t1886 = v_buf_part2_r
      _t1887 = L_wipe2
      _t1888 = _memset(_t1886, 0.0, _t1887)
      _t1882 = _t1888
    else:
      _t1882 = 0.0
    _t1889 = 1.0 if _tr((1.0 if abs(v_active_part - 3.0) < 0.00001 else 0.0)) else 0.0
    if _t1889:
      _t1889 = 1.0 if _tr((1.0 if L_wipe3 > 0.0 else 0.0)) else 0.0
    if _tr(_t1889):
      _t1891 = v_buf_part3_l
      _t1892 = L_wipe3
      _t1893 = _memset(_t1891, 0.0, _t1892)
      _t1894 = v_buf_part3_r
      _t1895 = L_wipe3
      _t1896 = _memset(_t1894, 0.0, _t1895)
      _t1890 = _t1896
    else:
      _t1890 = 0.0
    _t1866 = _t1890
  L_hi = 0.0
  for _t1897 in range(max(0, int(v_max_history))):
    _t1898 = _ix(v_hist_len + L_hi)
    _t1899 = 0.0
    _mset(_t1898, _t1899)
    L_hi = (L_hi + 1.0)
  if _tr((1.0 if abs(L_clear_type - 1.0) < 0.00001 else 0.0)):
    _t1901 = f_sy_clear(0.0)
    _t1902 = f_sy_clear(1.0)
    _t1903 = f_sy_clear(2.0)
    _t1900 = _t1903
  else:
    _t1904 = (v_active_part - 1.0)
    _t1905 = f_sy_clear(_t1904)
    _t1900 = _t1905
  v_rec_ref_kind = 0.0
  v_xarm = 0.0
  if _tr((1.0 if abs(L_clear_type - 1.0) < 0.00001 else 0.0)):
    v_len_part1 = 0.0
    v_len_part2 = 0.0
    v_len_part3 = 0.0
    v_base_len_part1 = 0.0
    v_base_len_part2 = 0.0
    v_base_len_part3 = 0.0
    v_master_pos1 = 0.0
    v_master_pos2 = 0.0
    v_master_pos3 = 0.0
    v_active_part = 1.0
    v_target_part = 1.0
    v_pending_part_switch = 0.0
    v_i = 0.0
    for _t1907 in range(max(0, int(3.0))):
      _t1908 = _ix(v_part_speed + v_i)
      _t1909 = 1.0
      _mset(_t1908, _t1909)
      _t1910 = _ix(v_part_pitch + v_i)
      _t1911 = 0.0
      _mset(_t1910, _t1911)
      _t1912 = _ix(v_part_rev + v_i)
      _t1913 = 0.0
      _mset(_t1912, _t1913)
      _t1914 = _ix(v_part_pingpong + v_i)
      _t1915 = 0.0
      _mset(_t1914, _t1915)
      _t1916 = _ix(v_part_play_mode + v_i)
      _t1917 = 0.0
      _mset(_t1916, _t1917)
      _t1918 = _ix(v_part_cloud_on + v_i)
      _t1919 = 0.0
      _mset(_t1918, _t1919)
      _t1920 = _ix(v_part_link_on + v_i)
      _t1921 = 0.0
      _mset(_t1920, _t1921)
      v_i = (v_i + 1.0)
    _t1922 = f_switch_history_slot(0.0)
    v_history_head = 0.0
    v_history_count = 1.0
    v_hist_undo = 0.0
    v_hist_redo = 0.0
    v_active_history_idx = 0.0
    _t1923 = 1.0 if _tr((1.0 if abs(_gget(0.0) - 1.0) < 0.00001 else 0.0)) else 0.0
    if _t1923:
      _t1924 = 1.0 if _tr((1.0 if abs(_gget(1.0) - v_instance_id) < 0.00001 else 0.0)) else 0.0
      if not _t1924:
        _t1924 = 1.0 if _tr((1.0 if abs(_gget(1.0) - v_instance_alias) < 0.00001 else 0.0)) else 0.0
      _t1923 = 1.0 if _tr(_t1924) else 0.0
    if _tr(_t1923):
      _t1926 = _ix(0.0)
      _t1927 = 0.0
      _gset(_t1926, _t1927)
      _t1925 = _t1927
    else:
      _t1925 = 0.0
    _t1928 = 1.0 if _tr((1.0 if abs(_gget(10.0) - 1.0) < 0.00001 else 0.0)) else 0.0
    if _t1928:
      _t1929 = 1.0 if _tr((1.0 if abs(_gget(11.0) - v_instance_id) < 0.00001 else 0.0)) else 0.0
      if not _t1929:
        _t1929 = 1.0 if _tr((1.0 if abs(_gget(11.0) - v_instance_alias) < 0.00001 else 0.0)) else 0.0
      _t1928 = 1.0 if _tr(_t1929) else 0.0
    if _tr(_t1928):
      _t1931 = _ix(10.0)
      _t1932 = 0.0
      _gset(_t1931, _t1932)
      _t1930 = _t1932
    else:
      _t1930 = 0.0
    _t1933 = 1.0 if _tr((1.0 if abs(_gget(20.0) - 1.0) < 0.00001 else 0.0)) else 0.0
    if _t1933:
      _t1934 = 1.0 if _tr((1.0 if abs(_gget(21.0) - v_instance_id) < 0.00001 else 0.0)) else 0.0
      if not _t1934:
        _t1934 = 1.0 if _tr((1.0 if abs(_gget(21.0) - v_instance_alias) < 0.00001 else 0.0)) else 0.0
      _t1933 = 1.0 if _tr(_t1934) else 0.0
    if _tr(_t1933):
      _t1936 = _ix(20.0)
      _t1937 = 0.0
      _gset(_t1936, _t1937)
      _t1935 = _t1937
    else:
      _t1935 = 0.0
    _t1906 = _t1935
  else:
    if _tr((1.0 if abs(v_active_part - 1.0) < 0.00001 else 0.0)):
      v_len_part1 = 0.0
      v_base_len_part1 = 0.0
      v_master_pos1 = 0.0
      _t1938 = v_master_pos1
    else:
      if _tr((1.0 if abs(v_active_part - 2.0) < 0.00001 else 0.0)):
        v_len_part2 = 0.0
        v_base_len_part2 = 0.0
        v_master_pos2 = 0.0
        _t1939 = v_master_pos2
      else:
        v_len_part3 = 0.0
        v_base_len_part3 = 0.0
        v_master_pos3 = 0.0
        _t1939 = v_master_pos3
      _t1938 = _t1939
    v_idx_clr = (v_active_part - 1.0)
    _t1940 = _ix(v_part_speed + v_idx_clr)
    _t1941 = 1.0
    _mset(_t1940, _t1941)
    _t1942 = _ix(v_part_pitch + v_idx_clr)
    _t1943 = 0.0
    _mset(_t1942, _t1943)
    _t1944 = _ix(v_part_rev + v_idx_clr)
    _t1945 = 0.0
    _mset(_t1944, _t1945)
    _t1946 = _ix(v_part_pingpong + v_idx_clr)
    _t1947 = 0.0
    _mset(_t1946, _t1947)
    _t1948 = _ix(v_part_play_mode + v_idx_clr)
    _t1949 = 0.0
    _mset(_t1948, _t1949)
    _t1950 = _ix(v_part_cloud_on + v_idx_clr)
    _t1951 = 0.0
    _mset(_t1950, _t1951)
    _t1952 = _ix(v_part_link_on + v_idx_clr)
    _t1953 = 0.0
    _mset(_t1952, _t1953)
    _t1954 = f_switch_history_slot(0.0)
    v_history_head = 0.0
    v_history_count = 1.0
    v_hist_undo = 0.0
    v_hist_redo = 0.0
    v_active_history_idx = 0.0
    v_pending_part_switch = 0.0
    L_ms_off = ((v_active_part - 1.0) * 10.0)
    _t1955 = 1.0 if _tr((1.0 if abs(_gget(L_ms_off) - 1.0) < 0.00001 else 0.0)) else 0.0
    if _t1955:
      _t1956 = 1.0 if _tr((1.0 if abs(_gget((L_ms_off + 1.0)) - v_instance_id) < 0.00001 else 0.0)) else 0.0
      if not _t1956:
        _t1956 = 1.0 if _tr((1.0 if abs(_gget((L_ms_off + 1.0)) - v_instance_alias) < 0.00001 else 0.0)) else 0.0
      _t1955 = 1.0 if _tr(_t1956) else 0.0
    if _tr(_t1955):
      _t1958 = _ix(L_ms_off)
      _t1959 = 0.0
      _gset(_t1958, _t1959)
      _t1957 = _t1959
    else:
      _t1957 = 0.0
    _t1906 = _t1957
  v_last_state_target = 0.0
  v_state = 0.0
  v_state_transition_fade = 0.0
  v_xf_on = 0.0
  v_rd_valid = 0.0
  v_rp_tail_on = 0.0
  v_frz_ready = 0.0
  v_frz_copying = 0.0
  v_frz_prev = (-1.0)
  v_sync_hard_resync = 1.0
  return v_sync_hard_resync

def f_slicer_mode_name(L_m):
  if _tr((1.0 if abs(L_m - 0.0) < 0.00001 else 0.0)):
    _t1960 = 0.0
  else:
    if _tr((1.0 if abs(L_m - 5.0) < 0.00001 else 0.0)):
      _t1961 = 0.0
    else:
      _t1961 = 0.0
    _t1960 = _t1961
  return _t1960

def f_grid_rate_name(L_m):
  if _tr((1.0 if abs(L_m - 0.0) < 0.00001 else 0.0)):
    _t1962 = 0.0
  else:
    if _tr((1.0 if abs(L_m - 1.0) < 0.00001 else 0.0)):
      _t1963 = 0.0
    else:
      if _tr((1.0 if abs(L_m - 2.0) < 0.00001 else 0.0)):
        _t1964 = 0.0
      else:
        if _tr((1.0 if abs(L_m - 3.0) < 0.00001 else 0.0)):
          _t1965 = 0.0
        else:
          if _tr((1.0 if abs(L_m - 4.0) < 0.00001 else 0.0)):
            _t1966 = 0.0
          else:
            if _tr((1.0 if abs(L_m - 5.0) < 0.00001 else 0.0)):
              _t1967 = 0.0
            else:
              if _tr((1.0 if abs(L_m - 6.0) < 0.00001 else 0.0)):
                _t1968 = 0.0
              else:
                if _tr((1.0 if abs(L_m - 7.0) < 0.00001 else 0.0)):
                  _t1969 = 0.0
                else:
                  if _tr((1.0 if abs(L_m - 8.0) < 0.00001 else 0.0)):
                    _t1970 = 0.0
                  else:
                    _t1970 = 0.0
                  _t1969 = _t1970
                _t1968 = _t1969
              _t1967 = _t1968
            _t1966 = _t1967
          _t1965 = _t1966
        _t1964 = _t1965
      _t1963 = _t1964
    _t1962 = _t1963
  return _t1962

def f_slicer_rate_name(L_m):
  if _tr((1.0 if abs(L_m - 0.0) < 0.00001 else 0.0)):
    _t1971 = 0.0
  else:
    if _tr((1.0 if abs(L_m - 1.0) < 0.00001 else 0.0)):
      _t1972 = 0.0
    else:
      if _tr((1.0 if abs(L_m - 2.0) < 0.00001 else 0.0)):
        _t1973 = 0.0
      else:
        if _tr((1.0 if abs(L_m - 3.0) < 0.00001 else 0.0)):
          _t1974 = 0.0
        else:
          if _tr((1.0 if abs(L_m - 4.0) < 0.00001 else 0.0)):
            _t1975 = 0.0
          else:
            _t1975 = 0.0
          _t1974 = _t1975
        _t1973 = _t1974
      _t1972 = _t1973
    _t1971 = _t1972
  return _t1971

def f_lfo_shape_name(L_s):
  if _tr((1.0 if abs(L_s - 0.0) < 0.00001 else 0.0)):
    _t1976 = 0.0
  else:
    if _tr((1.0 if abs(L_s - 1.0) < 0.00001 else 0.0)):
      _t1977 = 0.0
    else:
      _t1977 = 0.0
    _t1976 = _t1977
  return _t1976

def f_quant_name(L_q):
  if _tr((1.0 if abs(L_q - 0.0) < 0.00001 else 0.0)):
    _t1978 = 0.0
  else:
    if _tr((1.0 if abs(L_q - 1.0) < 0.00001 else 0.0)):
      _t1979 = 0.0
    else:
      if _tr((1.0 if abs(L_q - 2.0) < 0.00001 else 0.0)):
        _t1980 = 0.0
      else:
        if _tr((1.0 if abs(L_q - 3.0) < 0.00001 else 0.0)):
          _t1981 = 0.0
        else:
          if _tr((1.0 if abs(L_q - 4.0) < 0.00001 else 0.0)):
            _t1982 = 0.0
          else:
            if _tr((1.0 if abs(L_q - 5.0) < 0.00001 else 0.0)):
              _t1983 = 0.0
            else:
              if _tr((1.0 if abs(L_q - 6.0) < 0.00001 else 0.0)):
                _t1984 = 0.0
              else:
                if _tr((1.0 if abs(L_q - 7.0) < 0.00001 else 0.0)):
                  _t1985 = 0.0
                else:
                  if _tr((1.0 if abs(L_q - 8.0) < 0.00001 else 0.0)):
                    _t1986 = 0.0
                  else:
                    _t1986 = 0.0
                  _t1985 = _t1986
                _t1984 = _t1985
              _t1983 = _t1984
            _t1982 = _t1983
          _t1981 = _t1982
        _t1980 = _t1981
      _t1979 = _t1980
    _t1978 = _t1979
  return _t1978

def f_quant_val(L_q):
  if _tr((1.0 if abs(L_q - 0.0) < 0.00001 else 0.0)):
    _t1987 = 0.0
  else:
    if _tr((1.0 if abs(L_q - 1.0) < 0.00001 else 0.0)):
      _t1988 = 2.0
    else:
      if _tr((1.0 if abs(L_q - 2.0) < 0.00001 else 0.0)):
        _t1989 = 3.0
      else:
        if _tr((1.0 if abs(L_q - 3.0) < 0.00001 else 0.0)):
          _t1990 = 4.0
        else:
          if _tr((1.0 if abs(L_q - 4.0) < 0.00001 else 0.0)):
            _t1991 = 6.0
          else:
            if _tr((1.0 if abs(L_q - 5.0) < 0.00001 else 0.0)):
              _t1992 = 8.0
            else:
              if _tr((1.0 if abs(L_q - 6.0) < 0.00001 else 0.0)):
                _t1993 = 12.0
              else:
                if _tr((1.0 if abs(L_q - 7.0) < 0.00001 else 0.0)):
                  _t1994 = 16.0
                else:
                  if _tr((1.0 if abs(L_q - 8.0) < 0.00001 else 0.0)):
                    _t1995 = 32.0
                  else:
                    _t1995 = 64.0
                  _t1994 = _t1995
                _t1993 = _t1994
              _t1992 = _t1993
            _t1991 = _t1992
          _t1990 = _t1991
        _t1989 = _t1990
      _t1988 = _t1989
    _t1987 = _t1988
  return _t1987

def f_loop_max_len():
  global v_buf_len, v_length, v_pos, v_state
  if _tr((1.0 if v_length > 0.0 else 0.0)):
    _t1996 = v_length
  else:
    if _tr((1.0 if abs(v_state - 1.0) < 0.00001 else 0.0)):
      _t1997 = v_pos
    else:
      _t1997 = v_buf_len
    _t1996 = _t1997
  return _t1996

def f_quant_grid():
  global v_loop_quant
  L_ml = 0.0
  L_qv = 0.0
  _t1998 = f_loop_max_len()
  L_ml = _t1998
  _t1999 = v_loop_quant
  _t2000 = f_quant_val(_t1999)
  L_qv = _t2000
  _t2001 = 1.0 if _tr((1.0 if L_qv > 0.0 else 0.0)) else 0.0
  if _t2001:
    _t2001 = 1.0 if _tr((1.0 if L_ml > 0.0 else 0.0)) else 0.0
  if _tr(_t2001):
    _t2002 = _div(L_ml, L_qv)
  else:
    _t2002 = 0.0
  return _t2002

def f_min_width():
  global v_srate
  L_g = 0.0
  _t2003 = f_quant_grid()
  L_g = _t2003
  if _tr((1.0 if L_g > 0.0 else 0.0)):
    _t2004 = L_g
  else:
    _t2004 = (v_srate * 0.05)
  return _t2004

def f_apply_quant_start(L_val_s):
  L_ml = 0.0
  L_g = 0.0
  _t2005 = f_loop_max_len()
  L_ml = _t2005
  _t2006 = f_quant_grid()
  L_g = _t2006
  if _tr((1.0 if L_g > 0.0 else 0.0)):
    _t2008 = (_div(L_val_s, L_g) + 0.5)
    _t2009 = _floor(_t2008)
    L_val_s = (_t2009 * L_g)
    _t2007 = L_val_s
  else:
    _t2007 = 0.0
  _t2010 = L_val_s
  _t2012 = L_ml
  _t2011 = f_min_width()
  _t2013 = (_t2012 - _t2011)
  _t2014 = min(_t2010, _t2013)
  _t2015 = _t2014
  _t2016 = max(0.0, _t2015)
  return _t2016

def f_apply_quant_width(L_val_w, L_s_pos):
  L_ml = 0.0
  L_g = 0.0
  L_mw = 0.0
  _t2017 = f_loop_max_len()
  L_ml = _t2017
  _t2018 = f_quant_grid()
  L_g = _t2018
  _t2019 = f_min_width()
  L_mw = _t2019
  if _tr((1.0 if L_g > 0.0 else 0.0)):
    _t2021 = (_div(L_val_w, L_g) + 0.5)
    _t2022 = _floor(_t2021)
    L_val_w = (_t2022 * L_g)
    _t2020 = L_val_w
  else:
    _t2020 = 0.0
  _t2023 = L_mw
  _t2024 = L_val_w
  _t2025 = L_mw
  _t2026 = (L_ml - L_s_pos)
  _t2027 = max(_t2025, _t2026)
  _t2028 = _t2027
  _t2029 = min(_t2024, _t2028)
  _t2030 = _t2029
  _t2031 = max(_t2023, _t2030)
  return _t2031

def f_br_quant_len():
  global v_loop_quant, v_srate
  L_qv = 0.0
  L_hb = 0.0
  _t2032 = v_loop_quant
  _t2033 = f_quant_val(_t2032)
  L_qv = _t2033
  if _tr((1.0 if L_qv <= 0.0 else 0.0)):
    _t2034 = 0.0
  else:
    _t2035 = f_loop_beat_len()
    L_hb = _t2035
    _t2036 = (v_srate * 0.01)
    _t2037 = (L_hb * _div(4.0, L_qv))
    _t2038 = max(_t2036, _t2037)
    _t2034 = _t2038
  return _t2034

def f_do_beat_repeat(L_want):
  global v_br_bg_e, v_br_bg_pos, v_br_bg_s, v_br_on, v_br_saved_start, v_br_saved_width, v_br_suppress_an, v_length, v_loop_quant, v_loop_start, v_loop_width, v_pos, v_smooth_start, v_smooth_width, v_srate, v_sync_hard_resync, v_trans_count, v_trans_mem, v_xf_len_rs
  L_i = 0.0
  L_nx = 0.0
  L_g = 0.0
  L_cur = 0.0
  L_best = 0.0
  L_bd = 0.0
  L_d = 0.0
  if _tr((1.0 if v_length <= 0.0 else 0.0)):
    v_br_on = 0.0
    _t2039 = v_br_on
  else:
    if _tr(L_want):
      if _tr((0.0 if _tr(v_br_on) else 1.0)):
        v_br_saved_start = v_loop_start
        v_br_saved_width = v_loop_width
        v_br_bg_s = v_loop_start
        _t2042 = v_length
        _t2043 = (v_loop_start + v_loop_width)
        _t2044 = min(_t2042, _t2043)
        v_br_bg_e = _t2044
        _t2045 = v_br_bg_s
        _t2046 = (v_br_bg_e - 1.0)
        _t2047 = v_pos
        _t2048 = min(_t2046, _t2047)
        _t2049 = _t2048
        _t2050 = max(_t2045, _t2049)
        v_br_bg_pos = _t2050
        _t2041 = v_br_bg_pos
      else:
        _t2041 = 0.0
      _t2051 = v_pos
      _t2052 = (v_length - (v_srate * 0.01))
      _t2053 = min(_t2051, _t2052)
      _t2054 = _t2053
      _t2055 = max(0.0, _t2054)
      L_cur = _t2055
      L_best = L_cur
      L_bd = 1000000000000.0
      if _tr((1.0 if v_trans_count > 0.0 else 0.0)):
        L_i = 0.0
        for _t2057 in range(max(0, int(v_trans_count))):
          _t2058 = (_mget(v_trans_mem + L_i) - L_cur)
          _t2059 = abs(_t2058)
          L_d = _t2059
          if _tr((1.0 if L_d < L_bd else 0.0)):
            L_bd = L_d
            L_best = _mget(v_trans_mem + L_i)
            _t2060 = L_best
          else:
            _t2060 = 0.0
          L_i = (L_i + 1.0)
        _t2056 = 0.0
      else:
        _t2056 = 0.0
      _t2061 = L_best
      _t2062 = (v_length - (v_srate * 0.01))
      _t2063 = min(_t2061, _t2062)
      _t2064 = _t2063
      _t2065 = max(0.0, _t2064)
      v_loop_start = _t2065
      if _tr((1.0 if abs(v_loop_quant - 0.0) < 0.00001 else 0.0)):
        L_nx = v_length
        L_i = 0.0
        for _t2067 in range(max(0, int(v_trans_count))):
          _t2068 = 1.0 if _tr((1.0 if _mget(v_trans_mem + L_i) > (v_loop_start + 1.0) else 0.0)) else 0.0
          if _t2068:
            _t2068 = 1.0 if _tr((1.0 if _mget(v_trans_mem + L_i) < L_nx else 0.0)) else 0.0
          if _tr(_t2068):
            L_nx = _mget(v_trans_mem + L_i)
            _t2069 = L_nx
          else:
            _t2069 = 0.0
          L_i = (L_i + 1.0)
        _t2070 = (v_srate * 0.01)
        if _tr((1.0 if L_nx < v_length else 0.0)):
          _t2071 = L_nx
        else:
          _t2071 = v_length
        _t2072 = (_t2071 - v_loop_start)
        _t2073 = max(_t2070, _t2072)
        v_loop_width = _t2073
        _t2066 = v_loop_width
      else:
        _t2074 = f_br_quant_len()
        L_g = _t2074
        if _tr((1.0 if L_g > 0.0 else 0.0)):
          _t2076 = L_g
          _t2077 = (v_length - v_loop_start)
          _t2078 = min(_t2076, _t2077)
          v_loop_width = _t2078
          _t2075 = v_loop_width
        else:
          _t2079 = (v_srate * 0.01)
          _t2080 = (v_length - v_loop_start)
          _t2081 = max(_t2079, _t2080)
          v_loop_width = _t2081
          _t2075 = v_loop_width
        _t2066 = _t2075
      v_br_on = 1.0
      v_sync_hard_resync = 1.0
      v_br_suppress_an = 1.0
      v_smooth_start = v_loop_start
      v_smooth_width = v_loop_width
      _t2082 = v_xf_len_rs
      _t2083 = f_xf_begin(_t2082, 1.0)
      _t2040 = _t2083
    else:
      if _tr(v_br_on):
        v_loop_start = v_br_saved_start
        v_loop_width = v_br_saved_width
        v_br_on = 0.0
        v_sync_hard_resync = 1.0
        v_br_suppress_an = 1.0
        v_smooth_start = v_loop_start
        v_smooth_width = v_loop_width
        _t2085 = v_xf_len_rs
        _t2086 = f_xf_begin(_t2085, 1.0)
        _t2084 = _t2086
      else:
        _t2084 = 0.0
      _t2040 = _t2084
    _t2039 = _t2040
  return _t2039

def f_br_refresh():
  global v_br_on, v_br_suppress_an, v_length, v_loop_quant, v_loop_start, v_loop_width, v_smooth_start, v_smooth_width, v_srate, v_sync_hard_resync, v_trans_count, v_trans_mem, v_xf_len_rs
  L_i = 0.0
  L_nx = 0.0
  L_g = 0.0
  _t2087 = 1.0 if _tr(v_br_on) else 0.0
  if _t2087:
    _t2087 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
  if _tr(_t2087):
    if _tr((1.0 if abs(v_loop_quant - 0.0) < 0.00001 else 0.0)):
      L_nx = v_length
      L_i = 0.0
      for _t2090 in range(max(0, int(v_trans_count))):
        _t2091 = 1.0 if _tr((1.0 if _mget(v_trans_mem + L_i) > (v_loop_start + 1.0) else 0.0)) else 0.0
        if _t2091:
          _t2091 = 1.0 if _tr((1.0 if _mget(v_trans_mem + L_i) < L_nx else 0.0)) else 0.0
        if _tr(_t2091):
          L_nx = _mget(v_trans_mem + L_i)
          _t2092 = L_nx
        else:
          _t2092 = 0.0
        L_i = (L_i + 1.0)
      _t2093 = (v_srate * 0.01)
      if _tr((1.0 if L_nx < v_length else 0.0)):
        _t2094 = L_nx
      else:
        _t2094 = v_length
      _t2095 = (_t2094 - v_loop_start)
      _t2096 = max(_t2093, _t2095)
      v_loop_width = _t2096
      _t2089 = v_loop_width
    else:
      _t2097 = f_br_quant_len()
      L_g = _t2097
      if _tr((1.0 if L_g > 0.0 else 0.0)):
        _t2099 = L_g
        _t2100 = (v_length - v_loop_start)
        _t2101 = min(_t2099, _t2100)
        v_loop_width = _t2101
        _t2098 = v_loop_width
      else:
        _t2098 = 0.0
      _t2089 = _t2098
    v_sync_hard_resync = 1.0
    v_br_suppress_an = 1.0
    v_smooth_start = v_loop_start
    v_smooth_width = v_loop_width
    _t2102 = v_xf_len_rs
    _t2103 = f_xf_begin(_t2102, 1.0)
    _t2088 = _t2103
  else:
    _t2088 = 0.0
  return _t2088

def f_br_nearest_q(L_w):
  global v_srate
  L_q = 0.0
  L_best = 0.0
  L_bd = 0.0
  L_d = 0.0
  L_best = 7.0
  L_bd = 1000000000000.0
  L_q = 1.0
  for _t2104 in range(max(0, int(9.0))):
    _t2112 = L_w
    _t2105 = (v_srate * 0.01)
    _t2106 = f_loop_beat_len()
    _t2109 = _t2106
    _t2107 = L_q
    _t2108 = f_quant_val(_t2107)
    _t2110 = (_t2109 * _div(4.0, _t2108))
    _t2111 = max(_t2105, _t2110)
    _t2113 = (_t2112 - _t2111)
    _t2114 = abs(_t2113)
    L_d = _t2114
    if _tr((1.0 if L_d < L_bd else 0.0)):
      L_bd = L_d
      L_best = L_q
      _t2115 = L_best
    else:
      _t2115 = 0.0
    L_q = (L_q + 1.0)
  return L_best

def f_br_set_width(L_w):
  global v_loop_quant
  _t2116 = L_w
  _t2117 = f_br_nearest_q(_t2116)
  v_loop_quant = _t2117
  v_loop_quant = v_loop_quant
  _t2118 = f_br_refresh()
  return _t2118

def f_fmt_note(L_dst, L_n):
  L_nm = 0.0
  L_oc = 0.0
  _t2119 = L_n
  _t2120 = _floor(_t2119)
  L_nm = _mod(_t2120, 12.0)
  _t2121 = _div(L_n, 12.0)
  _t2122 = _floor(_t2121)
  L_oc = (_t2122 - 1.0)
  _t2123 = L_dst
  if _tr((1.0 if abs(L_nm - 0.0) < 0.00001 else 0.0)):
    _t2124 = 0.0
  else:
    if _tr((1.0 if abs(L_nm - 1.0) < 0.00001 else 0.0)):
      _t2125 = 0.0
    else:
      if _tr((1.0 if abs(L_nm - 2.0) < 0.00001 else 0.0)):
        _t2126 = 0.0
      else:
        if _tr((1.0 if abs(L_nm - 3.0) < 0.00001 else 0.0)):
          _t2127 = 0.0
        else:
          if _tr((1.0 if abs(L_nm - 4.0) < 0.00001 else 0.0)):
            _t2128 = 0.0
          else:
            if _tr((1.0 if abs(L_nm - 5.0) < 0.00001 else 0.0)):
              _t2129 = 0.0
            else:
              if _tr((1.0 if abs(L_nm - 6.0) < 0.00001 else 0.0)):
                _t2130 = 0.0
              else:
                if _tr((1.0 if abs(L_nm - 7.0) < 0.00001 else 0.0)):
                  _t2131 = 0.0
                else:
                  if _tr((1.0 if abs(L_nm - 8.0) < 0.00001 else 0.0)):
                    _t2132 = 0.0
                  else:
                    if _tr((1.0 if abs(L_nm - 9.0) < 0.00001 else 0.0)):
                      _t2133 = 0.0
                    else:
                      if _tr((1.0 if abs(L_nm - 10.0) < 0.00001 else 0.0)):
                        _t2134 = 0.0
                      else:
                        _t2134 = 0.0
                      _t2133 = _t2134
                    _t2132 = _t2133
                  _t2131 = _t2132
                _t2130 = _t2131
              _t2129 = _t2130
            _t2128 = _t2129
          _t2127 = _t2128
        _t2126 = _t2127
      _t2125 = _t2126
    _t2124 = _t2125
  _t2135 = _t2124
  _t2136 = L_oc
  return 0.0

def f_sampler_mode_now():
  global v_length, v_play_mode, v_state, v_trans_count
  _t2137 = 1.0 if _tr((1.0 if abs(v_state - 0.0) < 0.00001 else 0.0)) else 0.0
  if _t2137:
    _t2137 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
  if _tr(_t2137):
    if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)):
      if _tr((1.0 if v_trans_count > 0.0 else 0.0)):
        _t2140 = 1.0
      else:
        _t2140 = 0.0
      _t2139 = _t2140
    else:
      _t2139 = 2.0
    _t2138 = _t2139
  else:
    _t2138 = 0.0
  return _t2138

def f_sampler_slice_end(L_st):
  global v_length, v_loop_start, v_loop_width, v_trans_count, v_trans_mem
  L_i = 0.0
  L_nx = 0.0
  _t2141 = (v_loop_start + v_loop_width)
  _t2142 = v_length
  _t2143 = min(_t2141, _t2142)
  L_nx = _t2143
  if _tr((1.0 if L_nx <= (L_st + 16.0) else 0.0)):
    L_nx = v_length
    _t2144 = L_nx
  else:
    _t2144 = 0.0
  L_i = 0.0
  for _t2145 in range(max(0, int(v_trans_count))):
    _t2146 = 1.0 if _tr((1.0 if _mget(v_trans_mem + L_i) > (L_st + 1.0) else 0.0)) else 0.0
    if _t2146:
      _t2146 = 1.0 if _tr((1.0 if _mget(v_trans_mem + L_i) < L_nx else 0.0)) else 0.0
    if _tr(_t2146):
      L_nx = _mget(v_trans_mem + L_i)
      _t2147 = L_nx
    else:
      _t2147 = 0.0
    L_i = (L_i + 1.0)
  return L_nx

def f_sampler_release_all(L_step):
  global v_smp_nv, v_smp_voice, v_smp_vs
  L_v = 0.0
  L_vb = 0.0
  L_v = 0.0
  for _t2148 in range(max(0, int(v_smp_nv))):
    L_vb = (v_smp_voice + (L_v * v_smp_vs))
    if _tr((1.0 if abs(_mget(L_vb + 0.0) - 1.0) < 0.00001 else 0.0)):
      _t2150 = _ix(L_vb + 0.0)
      _t2151 = 2.0
      _mset(_t2150, _t2151)
      _t2152 = _ix(L_vb + 9.0)
      _t2153 = L_step
      _mset(_t2152, _t2153)
      _t2149 = _t2153
    else:
      _t2149 = 0.0
    L_v = (L_v + 1.0)
  return 0.0

def f_sampler_note_off(L_note):
  global v_sampler_release, v_smp_nv, v_smp_voice, v_smp_vs, v_srate
  L_v = 0.0
  L_vb = 0.0
  L_rt = 0.0
  L_rt = v_sampler_release
  L_v = 0.0
  for _t2154 in range(max(0, int(v_smp_nv))):
    L_vb = (v_smp_voice + (L_v * v_smp_vs))
    _t2156 = 1.0 if _tr((1.0 if abs(_mget(L_vb + 0.0) - 1.0) < 0.00001 else 0.0)) else 0.0
    if _t2156:
      _t2156 = 1.0 if _tr((1.0 if abs(_mget(L_vb + 6.0) - L_note) < 0.00001 else 0.0)) else 0.0
    _t2155 = 1.0 if _tr(_t2156) else 0.0
    if _t2155:
      _t2157 = 1.0 if _tr((1.0 if _mget(L_vb + 11.0) > 0.0 else 0.0)) else 0.0
      if not _t2157:
        _t2157 = 1.0 if _tr((1.0 if L_rt > 0.0 else 0.0)) else 0.0
      _t2155 = 1.0 if _tr(_t2157) else 0.0
    if _tr(_t2155):
      _t2159 = _ix(L_vb + 0.0)
      _t2160 = 2.0
      _mset(_t2159, _t2160)
      _t2161 = _ix(L_vb + 9.0)
      _t2162 = L_rt
      _t2163 = max(5.0, _t2162)
      _t2164 = _div(1.0, ((_t2163 * 0.001) * v_srate))
      _mset(_t2161, _t2164)
      _t2158 = _t2164
    else:
      _t2158 = 0.0
    L_v = (L_v + 1.0)
  return 0.0

def f_sampler_note_on(L_note, L_vel):
  global v_length, v_loop_start, v_loop_width, v_rev_on, v_sampler_pitch_mode, v_sampler_root, v_smp_age, v_smp_choke_rel, v_smp_mode, v_smp_nv, v_smp_voice, v_smp_vs, v_trans_count, v_trans_mem
  L_k = 0.0
  L_kmode = 0.0
  L_ok = 0.0
  L_st = 0.0
  L_en = 0.0
  L_v = 0.0
  L_vb = 0.0
  L_fr = 0.0
  L_old = 0.0
  L_old_age = 0.0
  L_kmode = (1.0 if abs(v_smp_mode - 2.0) < 0.00001 else 0.0)
  L_k = (L_note - v_sampler_root)
  if _tr(L_kmode):
    _t2165 = 1.0
  else:
    _t2166 = 1.0 if _tr((1.0 if L_k >= 0.0 else 0.0)) else 0.0
    if _t2166:
      _t2166 = 1.0 if _tr((1.0 if L_k < v_trans_count else 0.0)) else 0.0
    _t2165 = _t2166
  L_ok = _t2165
  if _tr(L_ok):
    if _tr(L_kmode):
      _t2169 = v_loop_start
      _t2170 = _floor(_t2169)
      L_st = _t2170
      _t2171 = (v_loop_start + v_loop_width)
      _t2172 = v_length
      _t2173 = min(_t2171, _t2172)
      _t2174 = _t2173
      _t2175 = _floor(_t2174)
      L_en = _t2175
      _t2168 = L_en
    else:
      _t2176 = _mget(v_trans_mem + L_k)
      _t2177 = _floor(_t2176)
      L_st = _t2177
      _t2178 = L_st
      _t2179 = f_sampler_slice_end(_t2178)
      _t2180 = _t2179
      _t2181 = _floor(_t2180)
      L_en = _t2181
      _t2168 = L_en
    if _tr((1.0 if L_en > (L_st + 8.0) else 0.0)):
      L_fr = (-1.0)
      L_old = 0.0
      L_old_age = 1000000000000.0
      L_v = 0.0
      for _t2183 in range(max(0, int(v_smp_nv))):
        L_vb = (v_smp_voice + (L_v * v_smp_vs))
        _t2184 = 1.0 if _tr((1.0 if abs(_mget(L_vb + 0.0) - 1.0) < 0.00001 else 0.0)) else 0.0
        if _t2184:
          _t2184 = 1.0 if _tr((1.0 if abs(_mget(L_vb + 6.0) - L_note) < 0.00001 else 0.0)) else 0.0
        if _tr(_t2184):
          _t2186 = _ix(L_vb + 0.0)
          _t2187 = 2.0
          _mset(_t2186, _t2187)
          _t2188 = _ix(L_vb + 9.0)
          _t2189 = v_smp_choke_rel
          _mset(_t2188, _t2189)
          _t2185 = _t2189
        else:
          _t2185 = 0.0
        _t2190 = 1.0 if _tr((1.0 if abs(_mget(L_vb + 0.0) - 0.0) < 0.00001 else 0.0)) else 0.0
        if _t2190:
          _t2190 = 1.0 if _tr((1.0 if L_fr < 0.0 else 0.0)) else 0.0
        if _tr(_t2190):
          L_fr = L_v
          _t2191 = L_fr
        else:
          _t2191 = 0.0
        _t2192 = 1.0 if _tr((1.0 if _mget(L_vb + 0.0) > 0.0 else 0.0)) else 0.0
        if _t2192:
          _t2192 = 1.0 if _tr((1.0 if _mget(L_vb + 8.0) < L_old_age else 0.0)) else 0.0
        if _tr(_t2192):
          L_old_age = _mget(L_vb + 8.0)
          L_old = L_v
          _t2193 = L_old
        else:
          _t2193 = 0.0
        L_v = (L_v + 1.0)
      if _tr((1.0 if L_fr < 0.0 else 0.0)):
        L_fr = L_old
        _t2194 = L_fr
      else:
        _t2194 = 0.0
      L_vb = (v_smp_voice + (L_fr * v_smp_vs))
      v_smp_age = (v_smp_age + 1.0)
      _t2195 = _ix(L_vb + 0.0)
      _t2196 = 1.0
      _mset(_t2195, _t2196)
      _t2197 = _ix(L_vb + 1.0)
      if _tr(v_rev_on):
        _t2198 = (L_en - 1.0)
      else:
        _t2198 = L_st
      _t2199 = _t2198
      _mset(_t2197, _t2199)
      _t2200 = _ix(L_vb + 2.0)
      _t2201 = L_st
      _mset(_t2200, _t2201)
      _t2202 = _ix(L_vb + 3.0)
      _t2203 = L_en
      _mset(_t2202, _t2203)
      _t2204 = _ix(L_vb + 4.0)
      _t2205 = _div(L_vel, 127.0)
      _mset(_t2204, _t2205)
      _t2206 = _ix(L_vb + 5.0)
      _t2207 = 0.0
      _mset(_t2206, _t2207)
      _t2208 = _ix(L_vb + 6.0)
      _t2209 = L_note
      _mset(_t2208, _t2209)
      _t2210 = _ix(L_vb + 7.0)
      if _tr(v_rev_on):
        _t2211 = (-1.0)
      else:
        _t2211 = 1.0
      _t2212 = _t2211
      _mset(_t2210, _t2212)
      _t2213 = _ix(L_vb + 8.0)
      _t2214 = 0.0
      _mset(_t2213, _t2214)
      _t2215 = _ix(L_vb + 9.0)
      _t2216 = 0.0
      _mset(_t2215, _t2216)
      _t2217 = _ix(L_vb + 10.0)
      if _tr(L_kmode):
        _t2218 = _pow(2.0, _div(L_k, 12.0))
      else:
        _t2218 = 1.0
      _t2219 = _t2218
      _mset(_t2217, _t2219)
      _t2220 = _ix(L_vb + 11.0)
      if _tr(L_kmode):
        if _tr((1.0 if abs(v_sampler_pitch_mode - 0.0) < 0.00001 else 0.0)):
          _t2222 = 1.0
        else:
          _t2222 = 2.0
        _t2221 = _t2222
      else:
        _t2221 = 0.0
      _t2223 = _t2221
      _mset(_t2220, _t2223)
      _t2224 = _ix(L_vb + 12.0)
      _t2225 = _mget(L_vb + 1.0)
      _mset(_t2224, _t2225)
      _t2226 = _ix(L_vb + 13.0)
      _t2227 = 0.0
      _mset(_t2226, _t2227)
      _t2228 = _ix(L_vb + 14.0)
      _t2229 = _mget(L_vb + 1.0)
      _mset(_t2228, _t2229)
      _t2230 = _ix(L_vb + 15.0)
      _t2231 = 1.0
      _mset(_t2230, _t2231)
      _t2182 = _t2231
    else:
      _t2182 = 0.0
    _t2167 = _t2182
  else:
    _t2167 = 0.0
  return _t2167

def f_sampler_read(L_p, L_st, L_en):
  global v_left_buf, v_right_buf, v_smp_rl, v_smp_rr
  L_i = 0.0
  L_fr = 0.0
  L_mx = 0.0
  L_a = 0.0
  L_b = 0.0
  L_c = 0.0
  L_d = 0.0
  _t2232 = L_p
  _t2233 = _floor(_t2232)
  L_i = _t2233
  L_fr = (L_p - L_i)
  L_mx = (L_en - 1.0)
  _t2234 = L_st
  _t2235 = L_mx
  _t2236 = (L_i - 1.0)
  _t2237 = min(_t2235, _t2236)
  _t2238 = _t2237
  _t2239 = max(_t2234, _t2238)
  L_a = _t2239
  _t2240 = L_st
  _t2241 = L_mx
  _t2242 = L_i
  _t2243 = min(_t2241, _t2242)
  _t2244 = _t2243
  _t2245 = max(_t2240, _t2244)
  L_b = _t2245
  _t2246 = L_st
  _t2247 = L_mx
  _t2248 = (L_i + 1.0)
  _t2249 = min(_t2247, _t2248)
  _t2250 = _t2249
  _t2251 = max(_t2246, _t2250)
  L_c = _t2251
  _t2252 = L_st
  _t2253 = L_mx
  _t2254 = (L_i + 2.0)
  _t2255 = min(_t2253, _t2254)
  _t2256 = _t2255
  _t2257 = max(_t2252, _t2256)
  L_d = _t2257
  _t2258 = L_fr
  _t2259 = _mget(v_left_buf + L_a)
  _t2260 = _mget(v_left_buf + L_b)
  _t2261 = _mget(v_left_buf + L_c)
  _t2262 = _mget(v_left_buf + L_d)
  _t2263 = f_hermite(_t2258, _t2259, _t2260, _t2261, _t2262)
  v_smp_rl = _t2263
  _t2264 = L_fr
  _t2265 = _mget(v_right_buf + L_a)
  _t2266 = _mget(v_right_buf + L_b)
  _t2267 = _mget(v_right_buf + L_c)
  _t2268 = _mget(v_right_buf + L_d)
  _t2269 = f_hermite(_t2264, _t2265, _t2266, _t2267, _t2268)
  v_smp_rr = _t2269
  return v_smp_rr

def f_sampler_render():
  global v_grain_ms, v_left_buf, v_length, v_lut_cos, v_lut_size, v_right_buf, v_slice_att_eff_ms, v_slice_decay_ms, v_smp_att, v_smp_g, v_smp_gh, v_smp_l, v_smp_nact, v_smp_nv, v_smp_r, v_smp_rl, v_smp_rr, v_smp_tail, v_smp_voice, v_smp_vs, v_srate
  L_v = 0.0
  L_vb = 0.0
  L_p = 0.0
  L_d = 0.0
  L_m = 0.0
  L_i = 0.0
  L_rem = 0.0
  L_g = 0.0
  L_dead = 0.0
  L_ph = 0.0
  L_ageb = 0.0
  L_wa = 0.0
  L_wb = 0.0
  L_sa = 0.0
  L_sb = 0.0
  L_r = 0.0
  L_slice_env_smp = 0.0
  L_slice_decay_step_smp = 0.0
  v_smp_l = 0.0
  v_smp_r = 0.0
  v_smp_nact = 0.0
  L_v = 0.0
  _t2270 = ((v_srate * v_grain_ms) * 0.001)
  _t2271 = _floor(_t2270)
  _t2272 = _t2271
  _t2273 = max(64.0, _t2272)
  v_smp_g = _t2273
  v_smp_gh = (v_smp_g * 0.5)
  for _t2274 in range(max(0, int(v_smp_nv))):
    L_vb = (v_smp_voice + (L_v * v_smp_vs))
    if _tr((1.0 if _mget(L_vb + 0.0) > 0.0 else 0.0)):
      v_smp_nact = (v_smp_nact + 1.0)
      L_p = _mget(L_vb + 1.0)
      L_d = _mget(L_vb + 7.0)
      L_m = _mget(L_vb + 11.0)
      _t2276 = L_p
      _t2277 = _floor(_t2276)
      L_i = _t2277
      if _tr((1.0 if L_d > 0.0 else 0.0)):
        _t2279 = (1.0 if L_p >= _mget(L_vb + 3.0) else 0.0)
      else:
        _t2279 = (1.0 if L_p < _mget(L_vb + 2.0) else 0.0)
      _t2278 = 1.0 if _tr(_t2279) else 0.0
      if not _t2278:
        _t2278 = 1.0 if _tr((1.0 if _mget(L_vb + 3.0) > v_length else 0.0)) else 0.0
      L_dead = _t2278
      if _tr(L_dead):
        _t2281 = _ix(L_vb + 0.0)
        _t2282 = 0.0
        _mset(_t2281, _t2282)
        _t2280 = _t2282
      else:
        if _tr((1.0 if abs(_mget(L_vb + 0.0) - 1.0) < 0.00001 else 0.0)):
          _t2284 = _ix(L_vb + 5.0)
          _t2285 = (_mget(L_vb + 5.0) + v_smp_att)
          _t2286 = min(1.0, _t2285)
          _t2287 = _t2286
          _mset(_t2284, _t2287)
          _t2283 = _t2287
        else:
          _t2288 = _ix(L_vb + 5.0)
          _t2289 = (_mget(_t2288) - _mget(L_vb + 9.0))
          _mset(_t2288, _t2289)
          if _tr((1.0 if _mget(L_vb + 5.0) <= 0.0 else 0.0)):
            _t2291 = _ix(L_vb + 5.0)
            _t2292 = 0.0
            _mset(_t2291, _t2292)
            _t2293 = _ix(L_vb + 0.0)
            _t2294 = 0.0
            _mset(_t2293, _t2294)
            _t2290 = _t2294
          else:
            _t2290 = 0.0
          _t2283 = _t2290
        if _tr((1.0 if L_d > 0.0 else 0.0)):
          _t2295 = (_mget(L_vb + 3.0) - L_p)
        else:
          _t2295 = ((L_p - _mget(L_vb + 2.0)) + 1.0)
        _t2297 = _t2295
        if _tr((1.0 if abs(L_m - 1.0) < 0.00001 else 0.0)):
          _t2296 = _mget(L_vb + 10.0)
        else:
          _t2296 = 1.0
        L_rem = _div(_t2297, _t2296)
        if _tr((1.0 if abs(_mget(L_vb + 0.0) - 2.0) < 0.00001 else 0.0)):
          _t2298 = (_mget(L_vb + 5.0) * _mget(L_vb + 5.0))
        else:
          _t2298 = _mget(L_vb + 5.0)
        L_g = (_t2298 * _mget(L_vb + 4.0))
        if _tr((1.0 if L_rem < v_smp_tail else 0.0)):
          _t2300 = _div(L_rem, v_smp_tail)
          _t2301 = max(0.0, _t2300)
          L_g = (L_g * _t2301)
          _t2299 = L_g
        else:
          _t2299 = 0.0
        _t2302 = _ix(L_vb + 8.0)
        _t2303 = (_mget(_t2302) + 1.0)
        _mset(_t2302, _t2303)
        if _tr((1.0 if v_slice_att_eff_ms > 0.0 else 0.0)):
          _t2307 = _mget(L_vb + 8.0)
          _t2305 = ((v_srate * v_slice_att_eff_ms) * 0.001)
          _t2306 = max(1.0, _t2305)
          _t2308 = _div(_t2307, _t2306)
          _t2309 = min(1.0, _t2308)
          L_g = (L_g * _t2309)
          _t2304 = L_g
        else:
          _t2304 = 0.0
        if _tr((1.0 if v_slice_decay_ms < 1950.0 else 0.0)):
          _t2313 = _mget(L_vb + 8.0)
          _t2311 = (v_srate * (v_slice_decay_ms * 0.001))
          _t2312 = max(2.0, _t2311)
          _t2314 = (1.0 - (_t2313 * _div(1.0, _t2312)))
          _t2315 = max(0.0, _t2314)
          L_g = (L_g * _t2315)
          _t2310 = L_g
        else:
          _t2310 = 0.0
        if _tr((1.0 if abs(L_m - 0.0) < 0.00001 else 0.0)):
          v_smp_l = (v_smp_l + (_mget(v_left_buf + L_i) * L_g))
          v_smp_r = (v_smp_r + (_mget(v_right_buf + L_i) * L_g))
          _t2317 = _ix(L_vb + 1.0)
          _t2318 = (L_p + L_d)
          _mset(_t2317, _t2318)
          _t2316 = _t2318
        else:
          if _tr((1.0 if abs(L_m - 1.0) < 0.00001 else 0.0)):
            _t2320 = L_p
            _t2321 = _mget(L_vb + 2.0)
            _t2322 = _mget(L_vb + 3.0)
            _t2323 = f_sampler_read(_t2320, _t2321, _t2322)
            v_smp_l = (v_smp_l + (v_smp_rl * L_g))
            v_smp_r = (v_smp_r + (v_smp_rr * L_g))
            _t2324 = _ix(L_vb + 1.0)
            _t2325 = (L_p + (L_d * _mget(L_vb + 10.0)))
            _mset(_t2324, _t2325)
            _t2319 = _t2325
          else:
            L_r = _mget(L_vb + 10.0)
            L_ph = (_mget(L_vb + 13.0) + 1.0)
            if _tr((1.0 if L_ph >= v_smp_g else 0.0)):
              L_ph = (L_ph - v_smp_g)
              _t2327 = _ix(L_vb + 12.0)
              _t2328 = L_p
              _mset(_t2327, _t2328)
              _t2329 = _ix(L_vb + 15.0)
              _t2330 = 0.0
              _mset(_t2329, _t2330)
              _t2326 = _t2330
            else:
              _t2326 = 0.0
            _t2331 = 1.0 if _tr((1.0 if _mget(L_vb + 13.0) < v_smp_gh else 0.0)) else 0.0
            if _t2331:
              _t2331 = 1.0 if _tr((1.0 if L_ph >= v_smp_gh else 0.0)) else 0.0
            if _tr(_t2331):
              _t2333 = _ix(L_vb + 14.0)
              _t2334 = L_p
              _mset(_t2333, _t2334)
              _t2332 = _t2334
            else:
              _t2332 = 0.0
            _t2335 = _ix(L_vb + 13.0)
            _t2336 = L_ph
            _mset(_t2335, _t2336)
            if _tr((1.0 if L_ph >= v_smp_gh else 0.0)):
              _t2337 = (L_ph - v_smp_gh)
            else:
              _t2337 = (L_ph + v_smp_gh)
            L_ageb = _t2337
            _t2338 = 1.0 if _tr(_mget(L_vb + 15.0)) else 0.0
            if _t2338:
              _t2338 = 1.0 if _tr((1.0 if L_ph < v_smp_gh else 0.0)) else 0.0
            if _tr(_t2338):
              _t2339 = 1.0
            else:
              _t2340 = (_div(L_ph, v_smp_g) * v_lut_size)
              _t2341 = _floor(_t2340)
              _t2339 = _mget(v_lut_cos + _mod(_t2341, v_lut_size))
            L_wa = _t2339
            _t2342 = 1.0 if _tr(_mget(L_vb + 15.0)) else 0.0
            if _t2342:
              _t2342 = 1.0 if _tr((1.0 if L_ph < v_smp_gh else 0.0)) else 0.0
            if _tr(_t2342):
              _t2343 = 0.0
            else:
              _t2344 = (_div(L_ageb, v_smp_g) * v_lut_size)
              _t2345 = _floor(_t2344)
              _t2343 = _mget(v_lut_cos + _mod(_t2345, v_lut_size))
            L_wb = _t2343
            L_sa = (_mget(L_vb + 12.0) + ((L_d * L_r) * L_ph))
            L_sb = (_mget(L_vb + 14.0) + ((L_d * L_r) * L_ageb))
            _t2347 = 1.0 if _tr((1.0 if L_wa > 0.0001 else 0.0)) else 0.0
            if _t2347:
              _t2347 = 1.0 if _tr((1.0 if L_sa >= _mget(L_vb + 2.0) else 0.0)) else 0.0
            _t2346 = 1.0 if _tr(_t2347) else 0.0
            if _t2346:
              _t2346 = 1.0 if _tr((1.0 if L_sa < _mget(L_vb + 3.0) else 0.0)) else 0.0
            if _tr(_t2346):
              _t2349 = L_sa
              _t2350 = _mget(L_vb + 2.0)
              _t2351 = _mget(L_vb + 3.0)
              _t2352 = f_sampler_read(_t2349, _t2350, _t2351)
              v_smp_l = (v_smp_l + ((v_smp_rl * L_g) * L_wa))
              v_smp_r = (v_smp_r + ((v_smp_rr * L_g) * L_wa))
              _t2348 = v_smp_r
            else:
              _t2348 = 0.0
            _t2354 = 1.0 if _tr((1.0 if L_wb > 0.0001 else 0.0)) else 0.0
            if _t2354:
              _t2354 = 1.0 if _tr((1.0 if L_sb >= _mget(L_vb + 2.0) else 0.0)) else 0.0
            _t2353 = 1.0 if _tr(_t2354) else 0.0
            if _t2353:
              _t2353 = 1.0 if _tr((1.0 if L_sb < _mget(L_vb + 3.0) else 0.0)) else 0.0
            if _tr(_t2353):
              _t2356 = L_sb
              _t2357 = _mget(L_vb + 2.0)
              _t2358 = _mget(L_vb + 3.0)
              _t2359 = f_sampler_read(_t2356, _t2357, _t2358)
              v_smp_l = (v_smp_l + ((v_smp_rl * L_g) * L_wb))
              v_smp_r = (v_smp_r + ((v_smp_rr * L_g) * L_wb))
              _t2355 = v_smp_r
            else:
              _t2355 = 0.0
            _t2360 = _ix(L_vb + 1.0)
            _t2361 = (L_p + L_d)
            _mset(_t2360, _t2361)
            _t2319 = _t2361
          _t2316 = _t2319
        _t2280 = _t2316
      _t2275 = _t2280
    else:
      _t2275 = 0.0
    L_v = (L_v + 1.0)
  return 0.0

def f_ui_arc(L_cx, L_cy, L_r, L_a0, L_a1):
  L_n = 0.0
  L_step = 0.0
  L_aa = 0.0
  L_bb = 0.0
  _t2362 = (L_a1 - L_a0)
  _t2363 = abs(_t2362)
  _t2364 = _div(_t2363, 0.12)
  _t2365 = _ceil(_t2364)
  _t2366 = _t2365
  _t2367 = max(1.0, _t2366)
  L_n = _t2367
  L_step = _div((L_a1 - L_a0), L_n)
  L_aa = L_a0
  for _t2368 in range(max(0, int(L_n))):
    L_bb = (L_aa + L_step)
    _t2371 = L_cx
    _t2369 = L_aa
    _t2370 = math.cos(_t2369)
    _t2372 = (_t2371 + (_t2370 * L_r))
    _t2375 = L_cy
    _t2373 = L_aa
    _t2374 = math.sin(_t2373)
    _t2376 = (_t2375 + (_t2374 * L_r))
    _t2379 = L_cx
    _t2377 = L_bb
    _t2378 = math.cos(_t2377)
    _t2380 = (_t2379 + (_t2378 * L_r))
    _t2383 = L_cy
    _t2381 = L_bb
    _t2382 = math.sin(_t2381)
    _t2384 = (_t2383 + (_t2382 * L_r))
    _t2387 = L_cx
    _t2385 = L_aa
    _t2386 = math.cos(_t2385)
    _t2388 = (_t2387 + (_t2386 * (L_r - 1.0)))
    _t2391 = L_cy
    _t2389 = L_aa
    _t2390 = math.sin(_t2389)
    _t2392 = (_t2391 + (_t2390 * (L_r - 1.0)))
    _t2395 = L_cx
    _t2393 = L_bb
    _t2394 = math.cos(_t2393)
    _t2396 = (_t2395 + (_t2394 * (L_r - 1.0)))
    _t2399 = L_cy
    _t2397 = L_bb
    _t2398 = math.sin(_t2397)
    _t2400 = (_t2399 + (_t2398 * (L_r - 1.0)))
    L_aa = L_bb
  return 0.0

def f_ui_text(L_x, L_y, L_str, L_r, L_g, L_b, L_a, L_align):
  global v_gfx_x, v_gfx_y
  L_tw = 0.0
  L_th = 0.0
  _t2401 = L_r
  _t2402 = L_g
  _t2403 = L_b
  _t2404 = L_a
  _t2405 = L_str
  _t2406 = L_tw
  _t2407 = L_th
  if _tr((1.0 if abs(L_align - 1.0) < 0.00001 else 0.0)):
    _t2408 = (L_x - L_tw)
  else:
    _t2408 = L_x
  v_gfx_x = _t2408
  v_gfx_y = L_y
  _t2409 = L_str
  return 0.0

def f_ui_panel(L_x, L_y, L_w, L_h, L_title):
  global v_b_bg, v_g_bg, v_gfx_x, v_gfx_y, v_r_bg, v_ui_ab, v_ui_ag, v_ui_ar
  _t2410 = (v_r_bg * 0.68)
  _t2411 = (v_g_bg * 0.68)
  _t2412 = (v_b_bg * 0.68)
  _t2413 = L_x
  _t2414 = L_y
  _t2415 = L_w
  _t2416 = L_h
  _t2417 = ((v_r_bg * 0.68) + 0.1)
  _t2418 = ((v_g_bg * 0.68) + 0.1)
  _t2419 = ((v_b_bg * 0.68) + 0.1)
  _t2420 = L_x
  _t2421 = L_y
  _t2422 = L_w
  _t2423 = L_h
  _t2424 = v_ui_ar
  _t2425 = v_ui_ag
  _t2426 = v_ui_ab
  _t2427 = L_x
  _t2428 = L_y
  _t2429 = L_w
  _t2430 = v_ui_ar
  _t2431 = v_ui_ag
  _t2432 = v_ui_ab
  v_gfx_x = (L_x + 10.0)
  v_gfx_y = (L_y + 5.0)
  _t2433 = L_title
  return 0.0

def f_ui_btn(L_x, L_y, L_w, L_h, L_label, L_on, L_cr, L_cg, L_cb):
  global v_gfx_x, v_gfx_y, v_mouse_click, v_mouse_x, v_mouse_y, v_ui_en, v_ui_hov
  L_hov = 0.0
  L_tw = 0.0
  L_th = 0.0
  L_ua = 0.0
  if _tr(v_ui_en):
    _t2434 = 1.0
  else:
    _t2434 = 0.4
  L_ua = _t2434
  _t2438 = 1.0 if _tr(v_ui_en) else 0.0
  if _t2438:
    _t2438 = 1.0 if _tr((1.0 if v_mouse_x >= L_x else 0.0)) else 0.0
  _t2437 = 1.0 if _tr(_t2438) else 0.0
  if _t2437:
    _t2437 = 1.0 if _tr((1.0 if v_mouse_x < (L_x + L_w) else 0.0)) else 0.0
  _t2436 = 1.0 if _tr(_t2437) else 0.0
  if _t2436:
    _t2436 = 1.0 if _tr((1.0 if v_mouse_y >= L_y else 0.0)) else 0.0
  _t2435 = 1.0 if _tr(_t2436) else 0.0
  if _t2435:
    _t2435 = 1.0 if _tr((1.0 if v_mouse_y < (L_y + L_h) else 0.0)) else 0.0
  L_hov = _t2435
  v_ui_hov = L_hov
  if _tr(L_on):
    _t2440 = L_cr
    _t2441 = L_cg
    _t2442 = L_cb
    _t2443 = L_ua
    _t2439 = 0.0
  else:
    if _tr(L_hov):
      _t2445 = L_ua
      _t2444 = 0.0
    else:
      _t2446 = L_ua
      _t2444 = 0.0
    _t2439 = _t2444
  _t2447 = L_x
  _t2448 = L_y
  _t2449 = L_w
  _t2450 = L_h
  if _tr(L_on):
    _t2451 = 0.2
  else:
    _t2451 = 0.06
  _t2452 = _t2451
  _t2453 = L_x
  _t2454 = L_y
  _t2455 = ((L_x + L_w) - 1.0)
  _t2456 = L_y
  _t2457 = L_cr
  _t2458 = L_cg
  _t2459 = L_cb
  if _tr(L_on):
    _t2460 = 0.0
  else:
    _t2460 = 0.8
  _t2461 = (_t2460 * L_ua)
  _t2462 = L_x
  _t2463 = ((L_y + L_h) - 2.0)
  _t2464 = L_w
  _t2465 = L_x
  _t2466 = L_y
  _t2467 = L_w
  _t2468 = L_h
  if _tr(L_on):
    _t2469 = 1.0
  else:
    _t2469 = 0.82
  _t2470 = (_t2469 * L_ua)
  _t2471 = L_label
  _t2472 = L_tw
  _t2473 = L_th
  v_gfx_x = (L_x + ((L_w - L_tw) * 0.5))
  v_gfx_y = (L_y + ((L_h - L_th) * 0.5))
  _t2474 = L_label
  _t2475 = 1.0 if _tr(v_mouse_click) else 0.0
  if _t2475:
    _t2475 = 1.0 if _tr(L_hov) else 0.0
  return _t2475

def f_ui_knob(L_id, L_cx, L_cy, L_r, L_val, L_mn, L_mx, L_label, L_fmt, L_def):
  global v_active_control, v_gfx_x, v_gfx_y, v_last_mouse_y, v_mouse_cap, v_mouse_click, v_mouse_x, v_mouse_y, v_ui_ab, v_ui_ag, v_ui_ar, v_ui_chg, v_ui_ds_on, v_ui_dv, v_ui_dv_on, v_ui_en
  L_rng = 0.0
  L_hot = 0.0
  L_d = 0.0
  L_norm = 0.0
  L_ang = 0.0
  L_ua = 0.0
  L_tw = 0.0
  L_th = 0.0
  L_act = 0.0
  v_ui_chg = 0.0
  _t2476 = (L_mx - L_mn)
  _t2477 = max(_t2476, 1e-06)
  L_rng = _t2477
  _t2479 = 1.0 if _tr(v_ui_en) else 0.0
  if _t2479:
    _t2480 = (v_mouse_x - L_cx)
    _t2481 = abs(_t2480)
    _t2479 = 1.0 if _tr((1.0 if _t2481 <= (L_r + 5.0) else 0.0)) else 0.0
  _t2478 = 1.0 if _tr(_t2479) else 0.0
  if _t2478:
    _t2482 = (v_mouse_y - L_cy)
    _t2483 = abs(_t2482)
    _t2478 = 1.0 if _tr((1.0 if _t2483 <= (L_r + 5.0) else 0.0)) else 0.0
  L_hot = _t2478
  _t2486 = 1.0 if _tr(v_ui_en) else 0.0
  if _t2486:
    _t2486 = 1.0 if _tr(v_mouse_click) else 0.0
  _t2485 = 1.0 if _tr(_t2486) else 0.0
  if _t2485:
    _t2485 = 1.0 if _tr((1.0 if abs(v_active_control - 0.0) < 0.00001 else 0.0)) else 0.0
  _t2484 = 1.0 if _tr(_t2485) else 0.0
  if _t2484:
    _t2484 = 1.0 if _tr(L_hot) else 0.0
  if _tr(_t2484):
    if _tr(float(int(v_mouse_cap) & int(4.0))):
      L_val = L_def
      v_ui_chg = 1.0
      _t2488 = v_ui_chg
    else:
      v_active_control = L_id
      _t2488 = v_active_control
    _t2487 = _t2488
  else:
    _t2487 = 0.0
  _t2489 = 1.0 if _tr(v_ui_en) else 0.0
  if _t2489:
    _t2489 = 1.0 if _tr((1.0 if abs(v_active_control - L_id) < 0.00001 else 0.0)) else 0.0
  if _tr(_t2489):
    L_d = (v_last_mouse_y - v_mouse_y)
    if _tr(float(int(v_mouse_cap) & int(8.0))):
      L_d = (L_d * 0.2)
      _t2491 = L_d
    else:
      _t2491 = 0.0
    if _tr((0.0 if abs(L_d - 0.0) < 0.00001 else 1.0)):
      _t2493 = L_mn
      _t2494 = L_mx
      _t2495 = (L_val + _div((L_d * L_rng), 200.0))
      _t2496 = min(_t2494, _t2495)
      _t2497 = _t2496
      _t2498 = max(_t2493, _t2497)
      L_val = _t2498
      v_ui_chg = 1.0
      _t2492 = v_ui_chg
    else:
      _t2492 = 0.0
    _t2490 = _t2492
  else:
    _t2490 = 0.0
  if _tr(v_ui_en):
    _t2499 = 1.0
  else:
    _t2499 = 0.4
  L_ua = _t2499
  L_act = (1.0 if abs(v_active_control - L_id) < 0.00001 else 0.0)
  _t2500 = _div((L_val - L_mn), L_rng)
  _t2501 = min(1.0, _t2500)
  _t2502 = _t2501
  _t2503 = max(0.0, _t2502)
  L_norm = _t2503
  L_ang = ((0.75 * 3.141592653589793) + ((L_norm * 1.5) * 3.141592653589793))
  _t2504 = L_ua
  _t2505 = L_cx
  _t2506 = L_cy
  _t2507 = (L_r - 2.0)
  _t2508 = L_ua
  _t2509 = L_cx
  _t2510 = L_cy
  _t2511 = (L_r - 2.0)
  _t2512 = L_ua
  _t2513 = L_cx
  _t2514 = L_cy
  _t2515 = (L_r + 3.0)
  _t2516 = (0.75 * 3.141592653589793)
  _t2517 = (2.25 * 3.141592653589793)
  _t2518 = f_ui_arc(_t2513, _t2514, _t2515, _t2516, _t2517)
  if _tr((1.0 if L_norm > 0.004 else 0.0)):
    _t2520 = v_ui_ar
    _t2521 = v_ui_ag
    _t2522 = v_ui_ab
    _t2523 = L_ua
    _t2524 = L_cx
    _t2525 = L_cy
    _t2526 = (L_r + 3.0)
    _t2527 = (0.75 * 3.141592653589793)
    _t2528 = L_ang
    _t2529 = f_ui_arc(_t2524, _t2525, _t2526, _t2527, _t2528)
    _t2519 = _t2529
  else:
    _t2519 = 0.0
  _t2531 = L_ua
  if _tr(L_act):
    _t2530 = 1.0
  else:
    _t2530 = 0.9
  _t2532 = (_t2531 * _t2530)
  _t2535 = L_cx
  _t2533 = L_ang
  _t2534 = math.cos(_t2533)
  _t2536 = (_t2535 + ((_t2534 * L_r) * 0.3))
  _t2539 = L_cy
  _t2537 = L_ang
  _t2538 = math.sin(_t2537)
  _t2540 = (_t2539 + ((_t2538 * L_r) * 0.3))
  _t2543 = L_cx
  _t2541 = L_ang
  _t2542 = math.cos(_t2541)
  _t2544 = (_t2543 + (_t2542 * (L_r - 4.0)))
  _t2547 = L_cy
  _t2545 = L_ang
  _t2546 = math.sin(_t2545)
  _t2548 = (_t2547 + (_t2546 * (L_r - 4.0)))
  _t2549 = L_ua
  _t2550 = L_label
  _t2551 = L_tw
  _t2552 = L_th
  v_gfx_x = (L_cx - (L_tw * 0.5))
  v_gfx_y = ((L_cy - L_r) - 18.0)
  _t2553 = L_label
  if _tr(v_ui_ds_on):
    _t2554 = 0.0
  else:
    _t2555 = L_fmt
    if _tr(v_ui_dv_on):
      _t2556 = v_ui_dv
    else:
      _t2556 = L_val
    _t2557 = _t2556
    _t2554 = 0.0
  v_ui_dv_on = 0.0
  v_ui_ds_on = 0.0
  _t2558 = 1.0 if _tr(L_act) else 0.0
  if not _t2558:
    _t2558 = 1.0 if _tr(L_hot) else 0.0
  if _tr(_t2558):
    _t2560 = L_ua
    _t2559 = 0.0
  else:
    _t2561 = L_ua
    _t2559 = 0.0
  _t2562 = L_tw
  _t2563 = L_th
  v_gfx_x = (L_cx - (L_tw * 0.5))
  v_gfx_y = ((L_cy + L_r) + 7.0)
  return L_val

def f_ui_hbar(L_id, L_x, L_y, L_w, L_h, L_val, L_mn, L_mx, L_def, L_fmt):
  global v_active_control, v_gfx_x, v_gfx_y, v_mouse_cap, v_mouse_click, v_mouse_x, v_mouse_y, v_ui_chg
  L_hot = 0.0
  L_nv = 0.0
  L_tw = 0.0
  L_th = 0.0
  L_tx = 0.0
  v_ui_chg = 0.0
  _t2566 = 1.0 if _tr((1.0 if v_mouse_x >= L_x else 0.0)) else 0.0
  if _t2566:
    _t2566 = 1.0 if _tr((1.0 if v_mouse_x < (L_x + L_w) else 0.0)) else 0.0
  _t2565 = 1.0 if _tr(_t2566) else 0.0
  if _t2565:
    _t2565 = 1.0 if _tr((1.0 if v_mouse_y >= (L_y - 3.0) else 0.0)) else 0.0
  _t2564 = 1.0 if _tr(_t2565) else 0.0
  if _t2564:
    _t2564 = 1.0 if _tr((1.0 if v_mouse_y <= ((L_y + L_h) + 3.0) else 0.0)) else 0.0
  L_hot = _t2564
  _t2568 = 1.0 if _tr(v_mouse_click) else 0.0
  if _t2568:
    _t2568 = 1.0 if _tr((1.0 if abs(v_active_control - 0.0) < 0.00001 else 0.0)) else 0.0
  _t2567 = 1.0 if _tr(_t2568) else 0.0
  if _t2567:
    _t2567 = 1.0 if _tr(L_hot) else 0.0
  if _tr(_t2567):
    if _tr(float(int(v_mouse_cap) & int(4.0))):
      L_val = L_def
      v_ui_chg = 1.0
      _t2570 = v_ui_chg
    else:
      v_active_control = L_id
      _t2570 = v_active_control
    _t2569 = _t2570
  else:
    _t2569 = 0.0
  if _tr((1.0 if abs(v_active_control - L_id) < 0.00001 else 0.0)):
    _t2576 = L_mn
    _t2572 = _div((v_mouse_x - L_x), L_w)
    _t2573 = min(1.0, _t2572)
    _t2574 = _t2573
    _t2575 = max(0.0, _t2574)
    L_nv = (_t2576 + (_t2575 * (L_mx - L_mn)))
    if _tr((0.0 if abs(L_nv - L_val) < 0.00001 else 1.0)):
      L_val = L_nv
      v_ui_chg = 1.0
      _t2577 = v_ui_chg
    else:
      _t2577 = 0.0
    _t2571 = _t2577
  else:
    _t2571 = 0.0
  _t2578 = L_x
  _t2579 = L_y
  _t2580 = L_w
  _t2581 = L_h
  _t2582 = L_x
  _t2583 = L_y
  _t2588 = L_w
  _t2584 = _div((L_val - L_mn), (L_mx - L_mn))
  _t2585 = min(1.0, _t2584)
  _t2586 = _t2585
  _t2587 = max(0.0, _t2586)
  _t2589 = (_t2588 * _t2587)
  _t2590 = L_h
  _t2591 = 1.0 if _tr(L_hot) else 0.0
  if not _t2591:
    _t2591 = 1.0 if _tr((1.0 if abs(v_active_control - L_id) < 0.00001 else 0.0)) else 0.0
  if _tr(_t2591):
    _t2593 = L_fmt
    _t2594 = L_val
    _t2595 = L_tw
    _t2596 = L_th
    _t2597 = L_x
    _t2598 = ((746.0 - L_tw) - 8.0)
    _t2599 = min(_t2597, _t2598)
    L_tx = _t2599
    _t2600 = (L_tx - 3.0)
    _t2601 = ((L_y - L_th) - 8.0)
    _t2602 = (L_tw + 8.0)
    _t2603 = (L_th + 4.0)
    v_gfx_x = L_tx
    v_gfx_y = ((L_y - L_th) - 6.0)
    _t2592 = 0.0
  else:
    _t2592 = 0.0
  return L_val

def f_ui_hbar_log(L_id, L_x, L_y, L_w, L_h, L_val, L_mn, L_mx, L_def, L_fmt):
  global v_active_control, v_gfx_x, v_gfx_y, v_mouse_cap, v_mouse_click, v_mouse_x, v_mouse_y, v_ui_chg
  L_hot = 0.0
  L_nv = 0.0
  L_tw = 0.0
  L_th = 0.0
  L_tx = 0.0
  L_lmn = 0.0
  L_lrg = 0.0
  v_ui_chg = 0.0
  _t2606 = 1.0 if _tr((1.0 if v_mouse_x >= L_x else 0.0)) else 0.0
  if _t2606:
    _t2606 = 1.0 if _tr((1.0 if v_mouse_x < (L_x + L_w) else 0.0)) else 0.0
  _t2605 = 1.0 if _tr(_t2606) else 0.0
  if _t2605:
    _t2605 = 1.0 if _tr((1.0 if v_mouse_y >= (L_y - 3.0) else 0.0)) else 0.0
  _t2604 = 1.0 if _tr(_t2605) else 0.0
  if _t2604:
    _t2604 = 1.0 if _tr((1.0 if v_mouse_y <= ((L_y + L_h) + 3.0) else 0.0)) else 0.0
  L_hot = _t2604
  _t2608 = 1.0 if _tr(v_mouse_click) else 0.0
  if _t2608:
    _t2608 = 1.0 if _tr((1.0 if abs(v_active_control - 0.0) < 0.00001 else 0.0)) else 0.0
  _t2607 = 1.0 if _tr(_t2608) else 0.0
  if _t2607:
    _t2607 = 1.0 if _tr(L_hot) else 0.0
  if _tr(_t2607):
    if _tr(float(int(v_mouse_cap) & int(4.0))):
      L_val = L_def
      v_ui_chg = 1.0
      _t2610 = v_ui_chg
    else:
      v_active_control = L_id
      _t2610 = v_active_control
    _t2609 = _t2610
  else:
    _t2609 = 0.0
  _t2611 = L_mn
  _t2612 = _log(_t2611)
  L_lmn = _t2612
  _t2613 = L_mx
  _t2614 = _log(_t2613)
  L_lrg = (_t2614 - L_lmn)
  if _tr((1.0 if abs(v_active_control - L_id) < 0.00001 else 0.0)):
    _t2620 = L_lmn
    _t2616 = _div((v_mouse_x - L_x), L_w)
    _t2617 = min(1.0, _t2616)
    _t2618 = _t2617
    _t2619 = max(0.0, _t2618)
    _t2621 = (_t2620 + (_t2619 * L_lrg))
    _t2622 = _exp(_t2621)
    L_nv = _t2622
    if _tr((0.0 if abs(L_nv - L_val) < 0.00001 else 1.0)):
      L_val = L_nv
      v_ui_chg = 1.0
      _t2623 = v_ui_chg
    else:
      _t2623 = 0.0
    _t2615 = _t2623
  else:
    _t2615 = 0.0
  _t2624 = L_x
  _t2625 = L_y
  _t2626 = L_w
  _t2627 = L_h
  _t2628 = L_x
  _t2629 = L_y
  _t2639 = L_w
  _t2630 = L_val
  _t2631 = L_mn
  _t2632 = max(_t2630, _t2631)
  _t2633 = _t2632
  _t2634 = _log(_t2633)
  _t2635 = _div((_t2634 - L_lmn), L_lrg)
  _t2636 = min(1.0, _t2635)
  _t2637 = _t2636
  _t2638 = max(0.0, _t2637)
  _t2640 = (_t2639 * _t2638)
  _t2641 = L_h
  _t2642 = 1.0 if _tr(L_hot) else 0.0
  if not _t2642:
    _t2642 = 1.0 if _tr((1.0 if abs(v_active_control - L_id) < 0.00001 else 0.0)) else 0.0
  if _tr(_t2642):
    _t2644 = L_fmt
    _t2645 = L_val
    _t2646 = L_tw
    _t2647 = L_th
    _t2648 = L_x
    _t2649 = ((746.0 - L_tw) - 8.0)
    _t2650 = min(_t2648, _t2649)
    L_tx = _t2650
    _t2651 = (L_tx - 3.0)
    _t2652 = ((L_y - L_th) - 8.0)
    _t2653 = (L_tw + 8.0)
    _t2654 = (L_th + 4.0)
    v_gfx_x = L_tx
    v_gfx_y = ((L_y - L_th) - 6.0)
    _t2643 = 0.0
  else:
    _t2643 = 0.0
  return L_val

def f_ui_log_knob(L_id, L_cx, L_cy, L_r, L_val, L_mn, L_mx, L_label, L_fmt, L_def):
  global v_active_control, v_gfx_x, v_gfx_y, v_last_mouse_y, v_mouse_cap, v_mouse_click, v_mouse_x, v_mouse_y, v_ui_ab, v_ui_ag, v_ui_ar, v_ui_chg, v_ui_ds_on, v_ui_en
  L_log_mn = 0.0
  L_log_mx = 0.0
  L_log_rng = 0.0
  L_log_val = 0.0
  L_hot = 0.0
  L_d = 0.0
  L_norm = 0.0
  L_ang = 0.0
  L_ua = 0.0
  L_tw = 0.0
  L_th = 0.0
  L_act = 0.0
  v_ui_chg = 0.0
  _t2655 = L_mn
  _t2656 = _log(_t2655)
  L_log_mn = _t2656
  _t2657 = L_mx
  _t2658 = _log(_t2657)
  L_log_mx = _t2658
  _t2659 = (L_log_mx - L_log_mn)
  _t2660 = max(_t2659, 1e-06)
  L_log_rng = _t2660
  _t2661 = L_val
  _t2662 = L_mn
  _t2663 = max(_t2661, _t2662)
  _t2664 = _t2663
  _t2665 = _log(_t2664)
  L_log_val = _t2665
  _t2667 = 1.0 if _tr(v_ui_en) else 0.0
  if _t2667:
    _t2668 = (v_mouse_x - L_cx)
    _t2669 = abs(_t2668)
    _t2667 = 1.0 if _tr((1.0 if _t2669 <= (L_r + 5.0) else 0.0)) else 0.0
  _t2666 = 1.0 if _tr(_t2667) else 0.0
  if _t2666:
    _t2670 = (v_mouse_y - L_cy)
    _t2671 = abs(_t2670)
    _t2666 = 1.0 if _tr((1.0 if _t2671 <= (L_r + 5.0) else 0.0)) else 0.0
  L_hot = _t2666
  _t2674 = 1.0 if _tr(v_ui_en) else 0.0
  if _t2674:
    _t2674 = 1.0 if _tr(v_mouse_click) else 0.0
  _t2673 = 1.0 if _tr(_t2674) else 0.0
  if _t2673:
    _t2673 = 1.0 if _tr((1.0 if abs(v_active_control - 0.0) < 0.00001 else 0.0)) else 0.0
  _t2672 = 1.0 if _tr(_t2673) else 0.0
  if _t2672:
    _t2672 = 1.0 if _tr(L_hot) else 0.0
  if _tr(_t2672):
    if _tr(float(int(v_mouse_cap) & int(4.0))):
      L_val = L_def
      v_ui_chg = 1.0
      _t2676 = v_ui_chg
    else:
      v_active_control = L_id
      _t2676 = v_active_control
    _t2675 = _t2676
  else:
    _t2675 = 0.0
  _t2677 = 1.0 if _tr(v_ui_en) else 0.0
  if _t2677:
    _t2677 = 1.0 if _tr((1.0 if abs(v_active_control - L_id) < 0.00001 else 0.0)) else 0.0
  if _tr(_t2677):
    L_d = (v_last_mouse_y - v_mouse_y)
    if _tr(float(int(v_mouse_cap) & int(8.0))):
      L_d = (L_d * 0.2)
      _t2679 = L_d
    else:
      _t2679 = 0.0
    if _tr((0.0 if abs(L_d - 0.0) < 0.00001 else 1.0)):
      _t2681 = L_log_mn
      _t2682 = L_log_mx
      _t2683 = (L_log_val + _div((L_d * L_log_rng), 200.0))
      _t2684 = min(_t2682, _t2683)
      _t2685 = _t2684
      _t2686 = max(_t2681, _t2685)
      L_log_val = _t2686
      _t2687 = L_log_val
      _t2688 = _exp(_t2687)
      L_val = _t2688
      v_ui_chg = 1.0
      _t2680 = v_ui_chg
    else:
      _t2680 = 0.0
    _t2678 = _t2680
  else:
    _t2678 = 0.0
  if _tr(v_ui_en):
    _t2689 = 1.0
  else:
    _t2689 = 0.4
  L_ua = _t2689
  L_act = (1.0 if abs(v_active_control - L_id) < 0.00001 else 0.0)
  _t2690 = _div((L_log_val - L_log_mn), L_log_rng)
  _t2691 = min(1.0, _t2690)
  _t2692 = _t2691
  _t2693 = max(0.0, _t2692)
  L_norm = _t2693
  L_ang = ((0.75 * 3.141592653589793) + ((L_norm * 1.5) * 3.141592653589793))
  _t2694 = L_ua
  _t2695 = L_cx
  _t2696 = L_cy
  _t2697 = (L_r - 2.0)
  _t2698 = L_ua
  _t2699 = L_cx
  _t2700 = L_cy
  _t2701 = (L_r - 2.0)
  _t2702 = L_ua
  _t2703 = L_cx
  _t2704 = L_cy
  _t2705 = (L_r + 3.0)
  _t2706 = (0.75 * 3.141592653589793)
  _t2707 = (2.25 * 3.141592653589793)
  _t2708 = f_ui_arc(_t2703, _t2704, _t2705, _t2706, _t2707)
  if _tr((1.0 if L_norm > 0.004 else 0.0)):
    _t2710 = v_ui_ar
    _t2711 = v_ui_ag
    _t2712 = v_ui_ab
    _t2713 = L_ua
    _t2714 = L_cx
    _t2715 = L_cy
    _t2716 = (L_r + 3.0)
    _t2717 = (0.75 * 3.141592653589793)
    _t2718 = L_ang
    _t2719 = f_ui_arc(_t2714, _t2715, _t2716, _t2717, _t2718)
    _t2709 = _t2719
  else:
    _t2709 = 0.0
  _t2721 = L_ua
  if _tr(L_act):
    _t2720 = 1.0
  else:
    _t2720 = 0.9
  _t2722 = (_t2721 * _t2720)
  _t2725 = L_cx
  _t2723 = L_ang
  _t2724 = math.cos(_t2723)
  _t2726 = (_t2725 + ((_t2724 * L_r) * 0.3))
  _t2729 = L_cy
  _t2727 = L_ang
  _t2728 = math.sin(_t2727)
  _t2730 = (_t2729 + ((_t2728 * L_r) * 0.3))
  _t2733 = L_cx
  _t2731 = L_ang
  _t2732 = math.cos(_t2731)
  _t2734 = (_t2733 + (_t2732 * (L_r - 4.0)))
  _t2737 = L_cy
  _t2735 = L_ang
  _t2736 = math.sin(_t2735)
  _t2738 = (_t2737 + (_t2736 * (L_r - 4.0)))
  _t2739 = L_ua
  _t2740 = L_label
  _t2741 = L_tw
  _t2742 = L_th
  v_gfx_x = (L_cx - (L_tw * 0.5))
  v_gfx_y = ((L_cy - L_r) - 18.0)
  _t2743 = L_label
  if _tr(v_ui_ds_on):
    _t2744 = 0.0
  else:
    _t2745 = L_fmt
    _t2746 = L_val
    _t2744 = 0.0
  v_ui_ds_on = 0.0
  _t2747 = 1.0 if _tr(L_act) else 0.0
  if not _t2747:
    _t2747 = 1.0 if _tr(L_hot) else 0.0
  if _tr(_t2747):
    _t2749 = L_ua
    _t2748 = 0.0
  else:
    _t2750 = L_ua
    _t2748 = 0.0
  _t2751 = L_tw
  _t2752 = L_th
  v_gfx_x = (L_cx - (L_tw * 0.5))
  v_gfx_y = ((L_cy + L_r) + 7.0)
  return L_val

def f_ld_fit_len(L_n, L_ml):
  L_best = 0.0
  L_bd = 0.0
  L_c = 0.0
  L_d = 0.0
  L_m = 0.0
  _t2753 = (_div(L_n, L_ml) + 0.5)
  _t2754 = _floor(_t2753)
  _t2755 = _t2754
  _t2756 = max(1.0, _t2755)
  L_m = _t2756
  L_best = (L_m * L_ml)
  _t2757 = _div(L_n, L_best)
  _t2758 = _log(_t2757)
  _t2759 = _t2758
  _t2760 = abs(_t2759)
  L_bd = _t2760
  L_c = (L_ml * 0.125)
  for _t2761 in range(max(0, int(3.0))):
    _t2762 = _div(L_n, L_c)
    _t2763 = _log(_t2762)
    _t2764 = _t2763
    _t2765 = abs(_t2764)
    L_d = _t2765
    if _tr((1.0 if L_d < L_bd else 0.0)):
      L_bd = L_d
      L_best = L_c
      _t2766 = L_best
    else:
      _t2766 = 0.0
    L_c = (L_c * 2.0)
  return L_best

def f_ld_query():
  global v_active_part, v_gmem, v_instance_alias, v_instance_id, v_ld_base, v_ld_maxn, v_single_buf_len
  L_ms_off = 0.0
  L_locked = 0.0
  L_mid = 0.0
  L_is_self = 0.0
  L_ml = 0.0
  L_n = 0.0
  L_ms_off = ((v_active_part - 1.0) * 10.0)
  L_locked = _gget(L_ms_off)
  L_mid = _gget((L_ms_off + 1.0))
  _t2767 = 1.0 if _tr((1.0 if abs(L_locked - 1.0) < 0.00001 else 0.0)) else 0.0
  if _t2767:
    _t2768 = 1.0 if _tr((1.0 if abs(L_mid - v_instance_id) < 0.00001 else 0.0)) else 0.0
    if not _t2768:
      _t2768 = 1.0 if _tr((1.0 if abs(L_mid - v_instance_alias) < 0.00001 else 0.0)) else 0.0
    _t2767 = 1.0 if _tr(_t2768) else 0.0
  L_is_self = _t2767
  if _tr((1.0 if abs(L_locked - 2.0) < 0.00001 else 0.0)):
    _t2770 = f_host_measure_len()
    _t2769 = _t2770
  else:
    _t2772 = 1.0 if _tr((1.0 if abs(L_locked - 1.0) < 0.00001 else 0.0)) else 0.0
    if _t2772:
      _t2772 = 1.0 if _tr((0.0 if _tr(L_is_self) else 1.0)) else 0.0
    _t2771 = 1.0 if _tr(_t2772) else 0.0
    if _t2771:
      _t2771 = 1.0 if _tr((1.0 if _gget((L_ms_off + 2.0)) > 0.0 else 0.0)) else 0.0
    if _tr(_t2771):
      _t2773 = _gget((L_ms_off + 2.0))
    else:
      _t2773 = 0.0
    _t2769 = _t2773
  L_ml = _t2769
  _t2774 = _gget((v_ld_base + 1.0))
  _t2775 = _floor(_t2774)
  L_n = _t2775
  _t2776 = _ix((v_ld_base + 4.0))
  if _tr((1.0 if L_ml > 0.0 else 0.0)):
    _t2777 = 1.0
  else:
    _t2777 = 0.0
  _t2778 = _t2777
  _gset(_t2776, _t2778)
  _t2779 = _ix((v_ld_base + 5.0))
  _t2780 = 1.0 if _tr((1.0 if L_ml > 0.0 else 0.0)) else 0.0
  if _t2780:
    _t2780 = 1.0 if _tr((1.0 if L_n > 0.0 else 0.0)) else 0.0
  if _tr(_t2780):
    _t2782 = L_n
    _t2783 = L_ml
    _t2784 = f_ld_fit_len(_t2782, _t2783)
    _t2785 = (_t2784 + 0.5)
    _t2786 = _floor(_t2785)
    _t2781 = _t2786
  else:
    _t2781 = L_n
  _t2787 = _t2781
  _gset(_t2779, _t2787)
  _t2788 = _ix((v_ld_base + 6.0))
  _t2789 = L_ml
  _gset(_t2788, _t2789)
  _t2790 = _ix((v_ld_base + 7.0))
  _t2791 = v_single_buf_len
  _t2792 = v_ld_maxn
  _t2793 = min(_t2791, _t2792)
  _t2794 = _t2793
  _gset(_t2790, _t2794)
  _t2795 = _ix((v_ld_base + 3.0))
  _t2796 = _gget((v_ld_base + 2.0))
  _gset(_t2795, _t2796)
  return _t2796

def f_ld_begin():
  global v_active_part, v_analysing, v_clk_cyc, v_dirty_len, v_gmem, v_hist_redo, v_hist_undo, v_history_count, v_history_head, v_last_state_target, v_ld_active, v_ld_base, v_ld_i, v_ld_maxn, v_ld_n, v_ld_part, v_ld_qid, v_ld_ref, v_length, v_loop_start, v_loop_width, v_master_pos, v_one_shot_playing, v_pos, v_rec_ref_kind, v_single_buf_len, v_state, v_state_target
  L_n = 0.0
  _t2797 = _gget((v_ld_base + 8.0))
  _t2798 = _floor(_t2797)
  L_n = _t2798
  _t2799 = _gget((v_ld_base + 9.0))
  _t2800 = _floor(_t2799)
  v_ld_ref = _t2800
  _t2801 = 1.0 if _tr((1.0 if L_n >= 1.0 else 0.0)) else 0.0
  if _t2801:
    _t2805 = L_n
    _t2802 = v_single_buf_len
    _t2803 = v_ld_maxn
    _t2804 = min(_t2802, _t2803)
    _t2801 = 1.0 if _tr((1.0 if _t2805 <= _t2804 else 0.0)) else 0.0
  if _tr(_t2801):
    v_ld_qid = _gget((v_ld_base + 2.0))
    _t2807 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
    if not _t2807:
      _t2807 = 1.0 if _tr((0.0 if abs(v_state - 0.0) < 0.00001 else 1.0)) else 0.0
    if _tr(_t2807):
      _t2809 = f_do_clear(0.0)
      _t2808 = _t2809
    else:
      _t2808 = 0.0
    v_state_target = 0.0
    v_last_state_target = 0.0
    v_state = 0.0
    v_analysing = 0.0
    v_one_shot_playing = 0.0
    _t2810 = f_switch_history_slot(0.0)
    v_history_head = 0.0
    v_history_count = 1.0
    v_hist_undo = 0.0
    v_hist_redo = 0.0
    v_dirty_len = 0.0
    v_pos = 0.0
    v_master_pos = 0.0
    v_clk_cyc = 0.0
    v_length = 0.0
    v_loop_start = 0.0
    v_loop_width = 0.0
    _t2811 = (v_active_part - 1.0)
    _t2812 = f_sy_clear(_t2811)
    v_rec_ref_kind = 0.0
    v_ld_active = 1.0
    v_ld_i = 0.0
    v_ld_n = L_n
    v_ld_part = v_active_part
    _t2806 = v_ld_part
  else:
    _t2806 = 0.0
  return _t2806

def f_ld_finish():
  global v_active_part, v_gmem, v_ld_active, v_ld_base, v_ld_n, v_ld_qid, v_ld_ref, v_length, v_part_sep, v_part_sm, v_part_sp, v_part_sref, v_pos, v_rec_ref_kind
  L_idx = 0.0
  L_mb = 0.0
  L_sp = 0.0
  L_locked = 0.0
  L_idx = (v_active_part - 1.0)
  v_pos = v_ld_n
  v_rec_ref_kind = 0.0
  _t2813 = f_finish_rec(0.0)
  if _tr((1.0 if abs(v_ld_ref - 1.0) < 0.00001 else 0.0)):
    L_locked = _gget((L_idx * 10.0))
    if _tr((1.0 if abs(L_locked - 2.0) < 0.00001 else 0.0)):
      _t2816 = _ix(v_part_sp + L_idx)
      _t2817 = 0.0
      _mset(_t2816, _t2817)
      _t2818 = _ix(v_part_sref + L_idx)
      _t2819 = 9.0
      _mset(_t2818, _t2819)
      _t2820 = _ix(v_part_sm + L_idx)
      _t2821 = f_host_measure_len()
      _t2822 = _t2821
      _mset(_t2820, _t2822)
      _t2823 = _ix(v_part_sep + L_idx)
      _t2824 = _gget((914.0 + L_idx))
      _mset(_t2823, _t2824)
      _t2815 = _t2824
    else:
      _t2825 = L_idx
      _t2826 = f_sy_master_blk(_t2825)
      L_mb = _t2826
      _t2827 = 1.0 if _tr((1.0 if L_mb >= 0.0 else 0.0)) else 0.0
      if _t2827:
        _t2828 = L_idx
        _t2829 = f_sy_is_master(_t2828)
        _t2827 = 1.0 if _tr((0.0 if _tr(_t2829) else 1.0)) else 0.0
      if _tr(_t2827):
        _t2831 = _ix(v_part_sref + L_idx)
        if _tr((1.0 if _gget((L_mb + 183.0)) > 0.0 else 0.0)):
          _t2832 = _gget((L_mb + 183.0))
        else:
          _t2832 = _gget(((L_idx * 10.0) + 1.0))
        _t2833 = _t2832
        _mset(_t2831, _t2833)
        _t2834 = _gget((L_mb + 182.0))
        _t2835 = max(0.0, _t2834)
        L_sp = _t2835
        _t2836 = _ix(v_part_sp + L_idx)
        _t2840 = L_sp
        _t2839 = v_length
        _t2837 = _div(L_sp, v_length)
        _t2838 = _floor(_t2837)
        _t2841 = (_t2840 - (_t2839 * _t2838))
        _mset(_t2836, _t2841)
        _t2842 = _ix(v_part_sm + L_idx)
        if _tr((1.0 if _gget((L_mb + 184.0)) > 0.0 else 0.0)):
          _t2844 = _gget((L_mb + 184.0))
          _t2845 = _gget(((L_idx * 10.0) + 2.0))
          _t2846 = min(_t2844, _t2845)
          _t2843 = _t2846
        else:
          _t2843 = _gget(((L_idx * 10.0) + 2.0))
        _t2847 = _t2843
        _mset(_t2842, _t2847)
        _t2830 = _t2847
      else:
        _t2830 = 0.0
      _t2815 = _t2830
    _t2814 = _t2815
  else:
    _t2814 = 0.0
  _t2848 = _ix((v_ld_base + 10.0))
  _t2849 = v_ld_qid
  _gset(_t2848, _t2849)
  v_ld_active = 0.0
  return v_ld_active

def f_ld_step():
  global v_active_part, v_gmem, v_ld_active, v_ld_base, v_ld_i, v_ld_maxn, v_ld_n, v_ld_part, v_left_buf, v_right_buf
  L_n_i = 0.0
  L_k = 0.0
  if _tr((0.0 if abs(v_active_part - v_ld_part) < 0.00001 else 1.0)):
    v_ld_active = 0.0
    _t2850 = v_ld_active
  else:
    _t2851 = (v_ld_n - v_ld_i)
    _t2852 = min(_t2851, 32768.0)
    L_n_i = _t2852
    L_k = 0.0
    for _t2853 in range(max(0, int(L_n_i))):
      _t2854 = _ix(v_left_buf + (v_ld_i + L_k))
      _t2855 = _gget((((v_ld_base + 16.0) + v_ld_i) + L_k))
      _mset(_t2854, _t2855)
      _t2856 = _ix(v_right_buf + (v_ld_i + L_k))
      _t2857 = _gget(((((v_ld_base + 16.0) + v_ld_maxn) + v_ld_i) + L_k))
      _mset(_t2856, _t2857)
      L_k = (L_k + 1.0)
    v_ld_i = (v_ld_i + L_n_i)
    if _tr((1.0 if v_ld_i >= v_ld_n else 0.0)):
      _t2859 = f_ld_finish()
      _t2858 = _t2859
    else:
      _t2858 = 0.0
    _t2850 = _t2858
  return _t2850

def f_dr_slot_l(L_idx):
  global v_active_part, v_buf_part1_l, v_buf_part2_l, v_buf_part3_l, v_hist_mem_start, v_slot_size
  if _tr((1.0 if abs(L_idx - 0.0) < 0.00001 else 0.0)):
    if _tr((1.0 if abs(v_active_part - 1.0) < 0.00001 else 0.0)):
      _t2861 = v_buf_part1_l
    else:
      if _tr((1.0 if abs(v_active_part - 2.0) < 0.00001 else 0.0)):
        _t2862 = v_buf_part2_l
      else:
        _t2862 = v_buf_part3_l
      _t2861 = _t2862
    _t2860 = _t2861
  else:
    _t2860 = (v_hist_mem_start + ((L_idx - 1.0) * v_slot_size))
  return _t2860

def f_dr_tau(L_p):
  global v_delay_len, v_effective_rev, v_length, v_link_eff, v_loop_start, v_loop_width, v_sm_speed, v_varispeed
  L_s = 0.0
  L_w = 0.0
  L_d = 0.0
  L_r = 0.0
  L_t = 0.0
  if _tr((1.0 if v_loop_width > 0.0 else 0.0)):
    _t2864 = v_loop_start
    _t2865 = _floor(_t2864)
    _t2863 = _t2865
  else:
    _t2863 = 0.0
  L_s = _t2863
  if _tr((1.0 if v_loop_width > 0.0 else 0.0)):
    _t2867 = v_loop_width
    _t2868 = _floor(_t2867)
    _t2866 = _t2868
  else:
    _t2869 = v_length
    _t2870 = _floor(_t2869)
    _t2866 = _t2870
  L_w = _t2866
  if _tr((1.0 if (L_s + L_w) > v_length else 0.0)):
    _t2872 = v_length
    _t2873 = _floor(_t2872)
    L_w = (_t2873 - L_s)
    _t2871 = L_w
  else:
    _t2871 = 0.0
  if _tr(v_effective_rev):
    _t2874 = (-1.0)
  else:
    _t2874 = 1.0
  L_d = _t2874
  if _tr(v_link_eff):
    _t2875 = v_varispeed
  else:
    _t2875 = v_sm_speed
  _t2876 = _t2875
  _t2877 = max(0.01, _t2876)
  L_r = _t2877
  L_t = (((L_d * (L_p - L_s)) + v_delay_len) - ((v_delay_len - 1.0) * L_r))
  _t2880 = L_w
  _t2878 = _div(L_t, L_w)
  _t2879 = _floor(_t2878)
  L_t = (L_t - (_t2880 * _t2879))
  return _div(L_t, L_r)

def f_dr_arm_target(L_tok):
  global v_active_part, v_dr_b, v_dr_base, v_dr_blk, v_dr_cnt, v_dr_l, v_dr_mode, v_dr_part, v_dr_slen, v_dr_spn, v_dr_t0, v_dr_t1, v_dr_tok, v_inst_idx, v_ld_active, v_ld_maxn, v_length, v_link_eff, v_loop_start, v_loop_width, v_part_sp, v_pos, v_samplesblock, v_single_buf_len, v_sm_speed, v_srate, v_state, v_varispeed
  L_b = 0.0
  L_s = 0.0
  L_w = 0.0
  L_r = 0.0
  L_sp = 0.0
  L_b = (v_dr_base + (v_inst_idx * 10.0))
  if _tr((1.0 if v_loop_width > 0.0 else 0.0)):
    _t2882 = v_loop_start
    _t2883 = _floor(_t2882)
    _t2881 = _t2883
  else:
    _t2881 = 0.0
  L_s = _t2881
  if _tr((1.0 if v_loop_width > 0.0 else 0.0)):
    _t2885 = v_loop_width
    _t2886 = _floor(_t2885)
    _t2884 = _t2886
  else:
    _t2887 = v_length
    _t2888 = _floor(_t2887)
    _t2884 = _t2888
  L_w = _t2884
  if _tr((1.0 if (L_s + L_w) > v_length else 0.0)):
    _t2890 = v_length
    _t2891 = _floor(_t2890)
    L_w = (_t2891 - L_s)
    _t2889 = L_w
  else:
    _t2889 = 0.0
  if _tr(v_link_eff):
    _t2892 = v_varispeed
  else:
    _t2892 = v_sm_speed
  _t2893 = _t2892
  _t2894 = max(0.01, _t2893)
  L_r = _t2894
  _t2895 = (_div(L_w, L_r) + 0.5)
  _t2896 = _floor(_t2895)
  v_dr_l = _t2896
  _t2904 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
  if _t2904:
    _t2904 = 1.0 if _tr((1.0 if L_w > 16.0 else 0.0)) else 0.0
  _t2903 = 1.0 if _tr(_t2904) else 0.0
  if _t2903:
    _t2903 = 1.0 if _tr((1.0 if v_state >= 2.0 else 0.0)) else 0.0
  _t2902 = 1.0 if _tr(_t2903) else 0.0
  if _t2902:
    _t2902 = 1.0 if _tr((1.0 if v_state <= 6.0 else 0.0)) else 0.0
  _t2901 = 1.0 if _tr(_t2902) else 0.0
  if _t2901:
    _t2901 = 1.0 if _tr((0.0 if _tr(v_ld_active) else 1.0)) else 0.0
  _t2900 = 1.0 if _tr(_t2901) else 0.0
  if _t2900:
    _t2900 = 1.0 if _tr((1.0 if v_dr_l > 256.0 else 0.0)) else 0.0
  _t2899 = 1.0 if _tr(_t2900) else 0.0
  if _t2899:
    _t2907 = v_dr_l
    _t2905 = (v_srate * 0.01)
    _t2906 = _floor(_t2905)
    _t2899 = 1.0 if _tr((1.0 if (_t2907 + _t2906) <= v_ld_maxn else 0.0)) else 0.0
  _t2898 = 1.0 if _tr(_t2899) else 0.0
  if _t2898:
    _t2898 = 1.0 if _tr((1.0 if v_dr_l <= v_single_buf_len else 0.0)) else 0.0
  _t2897 = 1.0 if _tr(_t2898) else 0.0
  if _t2897:
    _t2908 = 1.0 if _tr((1.0 if abs(v_dr_mode - 0.0) < 0.00001 else 0.0)) else 0.0
    if not _t2908:
      _t2908 = 1.0 if _tr((1.0 if abs(v_dr_mode - 3.0) < 0.00001 else 0.0)) else 0.0
    _t2897 = 1.0 if _tr(_t2908) else 0.0
  if _tr(_t2897):
    v_dr_tok = L_tok
    v_dr_b = L_b
    _t2910 = v_pos
    _t2911 = f_dr_tau(_t2910)
    v_dr_t0 = _t2911
    _t2914 = v_dr_l
    _t2912 = _div(v_dr_t0, v_dr_l)
    _t2913 = _floor(_t2912)
    v_dr_t0 = (v_dr_t0 - (_t2914 * _t2913))
    v_dr_cnt = 0.0
    v_dr_blk = v_samplesblock
    L_sp = _mget(v_part_sp + (v_active_part - 1.0))
    if _tr((1.0 if L_sp >= 0.0 else 0.0)):
      _t2916 = L_sp
      _t2917 = f_dr_tau(_t2916)
      _t2915 = (_t2917 - 1.0)
    else:
      _t2915 = (-1.0)
    v_dr_spn = _t2915
    if _tr((1.0 if v_dr_spn >= 0.0 else 0.0)):
      _t2921 = v_dr_l
      _t2919 = _div(v_dr_spn, v_dr_l)
      _t2920 = _floor(_t2919)
      v_dr_spn = (v_dr_spn - (_t2921 * _t2920))
      _t2918 = v_dr_spn
    else:
      _t2918 = 0.0
    v_dr_part = v_active_part
    v_dr_slen = v_length
    _t2922 = _time()
    v_dr_t1 = _t2922
    v_dr_mode = 1.0
    _t2923 = _ix((L_b + 5.0))
    _t2924 = v_dr_l
    _gset(_t2923, _t2924)
    _t2925 = _ix((L_b + 1.0))
    _t2926 = v_dr_t0
    _gset(_t2925, _t2926)
    _t2927 = _ix(L_b)
    _t2928 = L_tok
    _gset(_t2927, _t2928)
    _t2909 = _t2928
  else:
    _t2929 = _ix(L_b)
    _t2930 = (L_tok + 0.75)
    _gset(_t2929, _t2930)
    _t2909 = _t2930
  return _t2909

def f_dr_arm_source(L_tok):
  global v_dr_b, v_dr_base, v_dr_mode, v_dr_t1, v_dr_tok, v_inst_idx
  L_b = 0.0
  L_b = (v_dr_base + (v_inst_idx * 10.0))
  _t2931 = 1.0 if _tr((1.0 if abs(v_dr_mode - 0.0) < 0.00001 else 0.0)) else 0.0
  if not _t2931:
    _t2931 = 1.0 if _tr((1.0 if abs(v_dr_mode - 3.0) < 0.00001 else 0.0)) else 0.0
  if _tr(_t2931):
    v_dr_tok = L_tok
    v_dr_b = L_b
    _t2933 = _time()
    v_dr_t1 = _t2933
    v_dr_mode = 3.0
    _t2934 = _ix(L_b)
    _t2935 = L_tok
    _gset(_t2934, _t2935)
    _t2932 = _t2935
  else:
    _t2936 = _ix(L_b)
    _t2937 = (L_tok + 0.75)
    _gset(_t2936, _t2937)
    _t2932 = _t2937
  return _t2932

def f_dr_commit_begin(L_tok):
  global v_active_history_idx, v_dr_base, v_dr_j, v_dr_mode, v_dr_ni, v_dr_nl, v_dr_nr, v_dr_tok, v_gmem, v_inst_idx, v_max_history, v_single_buf_len
  _t2939 = 1.0 if _tr((1.0 if abs(v_dr_mode - 1.0) < 0.00001 else 0.0)) else 0.0
  if _t2939:
    _t2939 = 1.0 if _tr((1.0 if abs(L_tok - v_dr_tok) < 0.00001 else 0.0)) else 0.0
  _t2938 = 1.0 if _tr(_t2939) else 0.0
  if _t2938:
    _t2938 = 1.0 if _tr((1.0 if abs(_gget((v_dr_base + 94.0)) - L_tok) < 0.00001 else 0.0)) else 0.0
  if _tr(_t2938):
    v_dr_ni = _mod((v_active_history_idx + 1.0), v_max_history)
    _t2941 = v_dr_ni
    _t2942 = f_dr_slot_l(_t2941)
    v_dr_nl = _t2942
    v_dr_nr = (v_dr_nl + v_single_buf_len)
    v_dr_j = 0.0
    v_dr_mode = 2.0
    _t2940 = v_dr_mode
  else:
    _t2943 = _ix((v_dr_base + (v_inst_idx * 10.0)))
    _t2944 = (L_tok + 0.75)
    _gset(_t2943, _t2944)
    _t2940 = _t2944
  return _t2940

def f_dr_install():
  global v_active_part, v_base_backup_l, v_base_backup_r, v_base_len_part1, v_base_len_part2, v_base_len_part3, v_base_loop_length, v_br_on, v_cloud_freeze, v_cloud_on, v_dirty_len, v_dr_b, v_dr_cnt, v_dr_l, v_dr_mode, v_dr_ni, v_dr_spn, v_dr_t0, v_dr_tok, v_eff_end, v_eff_len, v_eff_start, v_fade_ms, v_hist_len, v_hist_redo, v_hist_undo, v_history_count, v_history_head, v_left_buf, v_len_part1, v_len_part2, v_len_part3, v_length, v_loop_start, v_loop_width, v_master_pos, v_max_history, v_mix, v_mult_len, v_old_pos_ptr, v_out_vol, v_part_sp, v_ping_pong_dir, v_pingpong_on, v_pitch, v_play_mode, v_pos, v_prev_cloud_on, v_prev_loop_start, v_prev_loop_width, v_prev_normal_playback, v_prev_pingpong_on, v_prev_play_mode, v_prev_rev_on, v_rev_on, v_right_buf, v_sm_pitch, v_sm_speed, v_smooth_start, v_smooth_width, v_speed, v_stereo_width, v_xfade_pos_active
  L_t = 0.0
  L_idx = 0.0
  L_idx = (v_active_part - 1.0)
  L_t = ((v_dr_t0 + v_dr_cnt) - 1.0)
  _t2947 = v_dr_l
  _t2945 = _div(L_t, v_dr_l)
  _t2946 = _floor(_t2945)
  L_t = (L_t - (_t2947 * _t2946))
  _t2948 = f_dub_flush()
  if _tr(v_br_on):
    _t2950 = f_do_beat_repeat(0.0)
    _t2949 = _t2950
  else:
    _t2949 = 0.0
  _t2951 = v_dr_ni
  _t2952 = f_switch_history_slot(_t2951)
  v_history_head = v_dr_ni
  _t2953 = _ix(v_hist_len + v_dr_ni)
  _t2954 = v_dr_l
  _mset(_t2953, _t2954)
  _t2955 = (v_hist_undo + 1.0)
  _t2956 = (v_max_history - 1.0)
  _t2957 = min(_t2955, _t2956)
  v_hist_undo = _t2957
  v_hist_redo = 0.0
  v_history_count = (v_hist_undo + 1.0)
  v_speed = 1.0
  v_speed = 1.0
  v_sm_speed = 1.0
  v_pitch = 0.0
  v_pitch = 0.0
  v_sm_pitch = 0.0
  v_rev_on = 0.0
  v_rev_on = 0.0
  v_pingpong_on = 0.0
  v_pingpong_on = 0.0
  v_ping_pong_dir = 1.0
  v_play_mode = 0.0
  v_play_mode = 0.0
  v_cloud_on = 0.0
  v_cloud_on = 0.0
  v_cloud_freeze = 0.0
  v_cloud_freeze = 0.0
  v_mix = 1.0
  v_mix = 1.0
  v_out_vol = 1.0
  v_out_vol = 1.0
  v_stereo_width = 0.0
  v_stereo_width = 0.0
  v_fade_ms = 0.0
  v_fade_ms = 0.0
  if _tr((0.0 if abs(v_dr_l - v_length) < 0.00001 else 1.0)):
    _t2961 = (v_base_loop_length * v_dr_l)
    _t2959 = v_length
    _t2960 = max(1.0, _t2959)
    _t2962 = (_div(_t2961, _t2960) + 0.5)
    _t2963 = _floor(_t2962)
    _t2964 = _t2963
    _t2965 = max(1.0, _t2964)
    v_base_loop_length = _t2965
    _t2958 = v_base_loop_length
  else:
    _t2958 = 0.0
  v_length = v_dr_l
  v_mult_len = v_length
  _t2966 = v_dirty_len
  _t2967 = v_length
  _t2968 = max(_t2966, _t2967)
  v_dirty_len = _t2968
  _t2969 = v_base_backup_l
  _t2970 = v_left_buf
  _t2971 = v_length
  _t2972 = _memcpy(_t2969, _t2970, _t2971)
  _t2973 = v_base_backup_r
  _t2974 = v_right_buf
  _t2975 = v_length
  _t2976 = _memcpy(_t2973, _t2974, _t2975)
  if _tr((1.0 if abs(v_active_part - 1.0) < 0.00001 else 0.0)):
    v_len_part1 = v_length
    v_base_len_part1 = v_base_loop_length
    _t2977 = v_base_len_part1
  else:
    _t2977 = 0.0
  if _tr((1.0 if abs(v_active_part - 2.0) < 0.00001 else 0.0)):
    v_len_part2 = v_length
    v_base_len_part2 = v_base_loop_length
    _t2978 = v_base_len_part2
  else:
    _t2978 = 0.0
  if _tr((1.0 if abs(v_active_part - 3.0) < 0.00001 else 0.0)):
    v_len_part3 = v_length
    v_base_len_part3 = v_base_loop_length
    _t2979 = v_base_len_part3
  else:
    _t2979 = 0.0
  v_loop_start = 0.0
  v_loop_width = v_length
  v_smooth_start = 0.0
  v_smooth_width = v_length
  v_eff_start = 0.0
  v_eff_end = v_length
  _t2980 = v_length
  _t2981 = max(_t2980, 16.0)
  v_eff_len = _t2981
  v_prev_loop_start = 0.0
  v_prev_loop_width = v_length
  if _tr((1.0 if v_master_pos >= v_length else 0.0)):
    _t2985 = v_length
    _t2983 = _div(v_master_pos, v_length)
    _t2984 = _floor(_t2983)
    v_master_pos = (v_master_pos - (_t2985 * _t2984))
    _t2982 = v_master_pos
  else:
    _t2982 = 0.0
  if _tr((1.0 if v_dr_spn >= 0.0 else 0.0)):
    _t2987 = _ix(v_part_sp + L_idx)
    _t2988 = v_dr_spn
    _mset(_t2987, _t2988)
    _t2986 = _t2988
  else:
    _t2986 = 0.0
  v_pos = L_t
  v_old_pos_ptr = L_t
  v_xfade_pos_active = 0.0
  v_prev_rev_on = 0.0
  v_prev_pingpong_on = 0.0
  v_prev_play_mode = 0.0
  v_prev_cloud_on = 0.0
  v_prev_normal_playback = 1.0
  _t2989 = f_start_analysis()
  _t2990 = _ix(v_dr_b)
  _t2991 = (v_dr_tok + 0.5)
  _gset(_t2990, _t2991)
  v_dr_mode = 0.0
  return v_dr_mode

def f_dr_step():
  global v_active_part, v_dr_b, v_dr_base, v_dr_blk, v_dr_cnt, v_dr_j, v_dr_l, v_dr_mode, v_dr_nl, v_dr_nr, v_dr_part, v_dr_slen, v_dr_t0, v_dr_t1, v_dr_tok, v_gmem, v_ld_base, v_ld_maxn, v_length, v_samplesblock, v_state_target
  L_n = 0.0
  L_k = 0.0
  L_a = 0.0
  L_t = 0.0
  L_sg = 0.0
  L_sg = _gget((v_dr_base + 80.0))
  _t2993 = 1.0 if _tr((1.0 if abs(v_dr_mode - 1.0) < 0.00001 else 0.0)) else 0.0
  if not _t2993:
    _t2993 = 1.0 if _tr((1.0 if abs(v_dr_mode - 2.0) < 0.00001 else 0.0)) else 0.0
  _t2992 = 1.0 if _tr(_t2993) else 0.0
  if not _t2992:
    _t2992 = 1.0 if _tr((1.0 if abs(v_dr_mode - 4.0) < 0.00001 else 0.0)) else 0.0
  if _tr(_t2992):
    v_dr_cnt = (v_dr_cnt + v_dr_blk)
    v_dr_blk = v_samplesblock
    L_t = (v_dr_t0 + v_dr_cnt)
    _t2997 = v_dr_l
    _t2995 = _div(L_t, v_dr_l)
    _t2996 = _floor(_t2995)
    L_t = (L_t - (_t2997 * _t2996))
    _t2998 = _ix((v_dr_b + 1.0))
    _t2999 = L_t
    _gset(_t2998, _t2999)
    _t3002 = 1.0 if _tr((0.0 if abs(v_active_part - v_dr_part) < 0.00001 else 1.0)) else 0.0
    if not _t3002:
      _t3002 = 1.0 if _tr((0.0 if abs(v_length - v_dr_slen) < 0.00001 else 1.0)) else 0.0
    _t3001 = 1.0 if _tr(_t3002) else 0.0
    if not _t3001:
      _t3001 = 1.0 if _tr((1.0 if abs(L_sg - (v_dr_tok + 0.75)) < 0.00001 else 0.0)) else 0.0
    _t3000 = 1.0 if _tr(_t3001) else 0.0
    if not _t3000:
      _t3003 = _time()
      _t3000 = 1.0 if _tr((1.0 if (_t3003 - v_dr_t1) > 200.0 else 0.0)) else 0.0
    if _tr(_t3000):
      if _tr((0.0 if abs(L_sg - (v_dr_tok + 0.75)) < 0.00001 else 1.0)):
        _t3006 = _ix(v_dr_b)
        _t3007 = (v_dr_tok + 0.75)
        _gset(_t3006, _t3007)
        _t3005 = _t3007
      else:
        _t3005 = 0.0
      v_dr_mode = 0.0
      _t3004 = v_dr_mode
    else:
      _t3004 = 0.0
    _t2994 = _t3004
  else:
    _t2994 = 0.0
  if _tr((1.0 if abs(v_dr_mode - 2.0) < 0.00001 else 0.0)):
    _t3009 = (v_dr_l - v_dr_j)
    _t3010 = min(_t3009, 32768.0)
    L_n = _t3010
    L_k = v_dr_j
    for _t3011 in range(max(0, int(L_n))):
      L_a = ((v_ld_base + 16.0) + L_k)
      _t3012 = _ix(v_dr_nl + L_k)
      _t3013 = _gget(L_a)
      _mset(_t3012, _t3013)
      _t3014 = _ix(v_dr_nr + L_k)
      _t3015 = _gget((L_a + v_ld_maxn))
      _mset(_t3014, _t3015)
      L_k = (L_k + 1.0)
    v_dr_j = L_k
    if _tr((1.0 if v_dr_j >= v_dr_l else 0.0)):
      _t3017 = _ix(v_dr_b)
      _t3018 = (v_dr_tok + 0.25)
      _gset(_t3017, _t3018)
      v_dr_mode = 4.0
      _t3016 = v_dr_mode
    else:
      _t3016 = 0.0
    _t3008 = _t3016
  else:
    if _tr((1.0 if abs(v_dr_mode - 4.0) < 0.00001 else 0.0)):
      if _tr((1.0 if abs(L_sg - (v_dr_tok + 0.5)) < 0.00001 else 0.0)):
        _t3021 = f_dr_install()
        _t3020 = _t3021
      else:
        _t3020 = 0.0
      _t3019 = _t3020
    else:
      if _tr((1.0 if abs(v_dr_mode - 3.0) < 0.00001 else 0.0)):
        if _tr((1.0 if abs(L_sg - (v_dr_tok + 0.5)) < 0.00001 else 0.0)):
          _t3024 = f_do_clear(0.0)
          v_state_target = 0.0
          v_dr_mode = 0.0
          _t3023 = v_dr_mode
        else:
          _t3025 = 1.0 if _tr((1.0 if abs(L_sg - (v_dr_tok + 0.75)) < 0.00001 else 0.0)) else 0.0
          if not _t3025:
            _t3026 = _time()
            _t3025 = 1.0 if _tr((1.0 if (_t3026 - v_dr_t1) > 200.0 else 0.0)) else 0.0
          if _tr(_t3025):
            v_dr_mode = 0.0
            _t3027 = v_dr_mode
          else:
            _t3027 = 0.0
          _t3023 = _t3027
        _t3022 = _t3023
      else:
        _t3022 = 0.0
      _t3019 = _t3022
    _t3008 = _t3019
  return _t3008

def f_rx_announce():
  global v_gmem, v_instance_id, v_rx_seen
  _t3028 = _ix(399.0)
  _t3029 = v_instance_id
  _gset(_t3028, _t3029)
  _t3030 = _ix(398.0)
  _t3031 = _time()
  _t3032 = _t3031
  _gset(_t3030, _t3032)
  v_rx_seen = _gget(398.0)
  return v_rx_seen

def f_rx_poll():
  global v_gmem, v_instance_id, v_pos, v_rec_cmd, v_rx_seen, v_srate, v_state
  if _tr((0.0 if abs(_gget(398.0) - v_rx_seen) < 0.00001 else 1.0)):
    v_rx_seen = _gget(398.0)
    _t3036 = (_gget(399.0) + 0.5)
    _t3037 = _floor(_t3036)
    _t3035 = 1.0 if _tr((0.0 if abs(_t3037 - v_instance_id) < 0.00001 else 1.0)) else 0.0
    if _t3035:
      _t3035 = 1.0 if _tr((1.0 if abs(v_state - 1.0) < 0.00001 else 0.0)) else 0.0
    _t3034 = 1.0 if _tr(_t3035) else 0.0
    if _t3034:
      _t3034 = 1.0 if _tr((1.0 if v_pos > (v_srate * 0.3) else 0.0)) else 0.0
    if _tr(_t3034):
      v_rec_cmd = 1.0
      _t3038 = v_rec_cmd
    else:
      _t3038 = 0.0
    _t3033 = _t3038
  else:
    _t3033 = 0.0
  return _t3033

def f_wp_beats():
  global v_warp_grid
  if _tr((1.0 if v_warp_grid < 0.5 else 0.0)):
    _t3039 = 1.0
  else:
    if _tr((1.0 if v_warp_grid < 1.5 else 0.0)):
      _t3040 = 0.5
    else:
      if _tr((1.0 if v_warp_grid < 2.5 else 0.0)):
        _t3041 = _div(1.0, 3.0)
      else:
        if _tr((1.0 if v_warp_grid < 3.5 else 0.0)):
          _t3042 = 0.25
        else:
          if _tr((1.0 if v_warp_grid < 4.5 else 0.0)):
            _t3043 = _div(1.0, 6.0)
          else:
            _t3043 = 0.125
          _t3042 = _t3043
        _t3041 = _t3042
      _t3040 = _t3041
    _t3039 = _t3040
  return _t3039

def f_wp_slot_l(L_idx):
  global v_active_part, v_buf_part1_l, v_buf_part2_l, v_buf_part3_l, v_hist_mem_start, v_slot_size
  if _tr((1.0 if abs(L_idx - 0.0) < 0.00001 else 0.0)):
    if _tr((1.0 if abs(v_active_part - 1.0) < 0.00001 else 0.0)):
      _t3045 = v_buf_part1_l
    else:
      if _tr((1.0 if abs(v_active_part - 2.0) < 0.00001 else 0.0)):
        _t3046 = v_buf_part2_l
      else:
        _t3046 = v_buf_part3_l
      _t3045 = _t3046
    _t3044 = _t3045
  else:
    _t3044 = (v_hist_mem_start + ((L_idx - 1.0) * v_slot_size))
  return _t3044

def f_wp_win_s():
  global v_br_on, v_br_saved_start, v_loop_start
  if _tr(v_br_on):
    _t3047 = v_br_saved_start
  else:
    _t3047 = v_loop_start
  return _t3047

def f_wp_win_w():
  global v_br_on, v_br_saved_width, v_loop_width
  if _tr(v_br_on):
    _t3048 = v_br_saved_width
  else:
    _t3048 = v_loop_width
  return _t3048

def f_wp_signature():
  global v_length, v_warp_force, v_warp_grid
  _t3049 = (v_warp_grid + 0.5)
  _t3050 = _floor(_t3049)
  _t3053 = (_t3050 * 1000003.0)
  _t3051 = (v_warp_force + 0.5)
  _t3052 = _floor(_t3051)
  _t3057 = (_t3053 + (_t3052 * 1009.0))
  _t3054 = f_wp_win_s()
  _t3055 = _t3054
  _t3056 = _floor(_t3055)
  _t3061 = (_t3057 + (_t3056 * 7.0))
  _t3058 = f_wp_win_w()
  _t3059 = _t3058
  _t3060 = _floor(_t3059)
  _t3065 = (_t3061 + (_t3060 * 13.0))
  _t3062 = f_loop_beat_len()
  _t3063 = _t3062
  _t3064 = _floor(_t3063)
  return ((_t3065 + (_t3064 * 3.0)) + (v_length * 17.0))

def f_wp_ix(L_x):
  global v_wp_ls, v_wp_lw
  _t3066 = L_x
  _t3067 = _floor(_t3066)
  L_x = _t3067
  _t3069 = v_wp_ls
  if _tr((1.0 if L_x >= 0.0 else 0.0)):
    _t3068 = _mod(L_x, v_wp_lw)
  else:
    _t3068 = _mod((v_wp_lw - _mod((0.0 - L_x), v_wp_lw)), v_wp_lw)
  return (_t3069 + _t3068)

def f_wp_abort():
  global v_an_after_wp, v_analysing, v_wp_busy, v_wp_phase, v_wp_scan
  if _tr(v_wp_busy):
    v_wp_busy = 0.0
    v_wp_phase = 0.0
    if _tr(v_wp_scan):
      v_wp_scan = 0.0
      v_analysing = 0.0
      v_an_after_wp = 1.0
      _t3071 = v_an_after_wp
    else:
      _t3071 = 0.0
    _t3070 = _t3071
  else:
    _t3070 = 0.0
  return _t3070

def f_wp_targets():
  global v_srate, v_warp_force, v_wp_dd, v_wp_ls, v_wp_lw, v_wp_mk, v_wp_mn, v_wp_n, v_wp_seg, v_wp_sr, v_wp_ss, v_wp_tg
  L_g = 0.0
  L_j = 0.0
  L_n = 0.0
  L_rel = 0.0
  L_q = 0.0
  L_t = 0.0
  L_d = 0.0
  L_ok = 0.0
  L_lk = 0.0
  L_mins = 0.0
  _t3072 = f_wp_win_s()
  _t3073 = _t3072
  _t3074 = _floor(_t3073)
  v_wp_ls = _t3074
  _t3075 = f_wp_win_w()
  _t3076 = _t3075
  _t3077 = _floor(_t3076)
  _t3078 = _t3077
  _t3079 = max(1.0, _t3078)
  v_wp_lw = _t3079
  _t3080 = (v_srate * 0.005)
  _t3081 = f_loop_beat_len()
  _t3083 = _t3081
  _t3082 = f_wp_beats()
  _t3084 = (_t3083 * _t3082)
  _t3085 = max(_t3080, _t3084)
  L_g = _t3085
  _t3086 = (v_srate * 0.02)
  _t3087 = _floor(_t3086)
  L_mins = _t3087
  L_n = 0.0
  L_j = 0.0
  for _t3088 in range(max(0, int(v_wp_mn))):
    _t3089 = _mget(v_wp_mk + L_j)
    _t3090 = _floor(_t3089)
    L_rel = (_t3090 - v_wp_ls)
    _t3091 = 1.0 if _tr((1.0 if L_rel >= 0.0 else 0.0)) else 0.0
    if _t3091:
      _t3091 = 1.0 if _tr((1.0 if L_rel < v_wp_lw else 0.0)) else 0.0
    if _tr(_t3091):
      _t3093 = (_div(L_rel, L_g) + 0.5)
      _t3094 = _floor(_t3093)
      L_q = (_t3094 * L_g)
      _t3100 = L_rel
      _t3099 = (L_q - L_rel)
      _t3095 = (v_warp_force * 0.01)
      _t3096 = min(1.0, _t3095)
      _t3097 = _t3096
      _t3098 = max(0.0, _t3097)
      _t3101 = ((_t3100 + (_t3099 * _t3098)) + 0.5)
      _t3102 = _floor(_t3101)
      L_t = _t3102
      _t3103 = (L_t - L_rel)
      _t3104 = abs(_t3103)
      L_d = _t3104
      L_ok = 1.0
      if _tr((1.0 if L_n > 0.0 else 0.0)):
        L_lk = (L_n - 1.0)
        _t3107 = 1.0 if _tr((1.0 if (L_t - _mget(v_wp_tg + L_lk)) < L_mins else 0.0)) else 0.0
        if not _t3107:
          _t3107 = 1.0 if _tr((1.0 if (L_t - _mget(v_wp_tg + L_lk)) > (3.0 * (L_rel - _mget(v_wp_sr + L_lk))) else 0.0)) else 0.0
        _t3106 = 1.0 if _tr(_t3107) else 0.0
        if not _t3106:
          _t3106 = 1.0 if _tr((1.0 if (3.0 * (L_t - _mget(v_wp_tg + L_lk))) < (L_rel - _mget(v_wp_sr + L_lk)) else 0.0)) else 0.0
        if _tr(_t3106):
          if _tr((1.0 if L_d < _mget(v_wp_dd + L_lk) else 0.0)):
            L_n = (L_n - 1.0)
            _t3109 = L_n
          else:
            L_ok = 0.0
            _t3109 = L_ok
          _t3108 = _t3109
        else:
          _t3108 = 0.0
        _t3105 = _t3108
      else:
        _t3105 = 0.0
      if _tr(L_ok):
        _t3111 = _ix(v_wp_sr + L_n)
        _t3112 = L_rel
        _mset(_t3111, _t3112)
        _t3113 = _ix(v_wp_tg + L_n)
        _t3114 = L_t
        _mset(_t3113, _t3114)
        _t3115 = _ix(v_wp_dd + L_n)
        _t3116 = L_d
        _mset(_t3115, _t3116)
        L_n = (L_n + 1.0)
        _t3110 = L_n
      else:
        _t3110 = 0.0
      _t3092 = _t3110
    else:
      _t3092 = 0.0
    L_j = (L_j + 1.0)
  _t3117 = 0
  while True:
    _t3118 = 1.0 if _tr((1.0 if L_n > 1.0 else 0.0)) else 0.0
    if _t3118:
      _t3119 = 1.0 if _tr((1.0 if ((_mget(v_wp_tg + 0.0) + v_wp_lw) - _mget(v_wp_tg + (L_n - 1.0))) < L_mins else 0.0)) else 0.0
      if not _t3119:
        _t3119 = 1.0 if _tr((1.0 if ((_mget(v_wp_sr + 0.0) + v_wp_lw) - _mget(v_wp_sr + (L_n - 1.0))) < L_mins else 0.0)) else 0.0
      _t3118 = 1.0 if _tr(_t3119) else 0.0
    if not _tr(_t3118): break
    L_n = (L_n - 1.0)
    _t3117 += 1
    if _t3117 > 1000000: break
  v_wp_n = L_n
  v_wp_seg = 0.0
  v_wp_ss = 0.0
  return v_wp_ss

def f_wp_seg_init():
  global v_srate, v_wp_a, v_wp_atk, v_wp_b, v_wp_cp, v_wp_gn, v_wp_hop, v_wp_j, v_wp_lout, v_wp_lsrc, v_wp_lw, v_wp_n, v_wp_pr, v_wp_rr, v_wp_seg, v_wp_sr, v_wp_ta, v_wp_tb, v_wp_tg, v_wp_xn
  L_k1 = 0.0
  L_k1 = (v_wp_seg + 1.0)
  v_wp_a = _mget(v_wp_sr + v_wp_seg)
  v_wp_ta = _mget(v_wp_tg + v_wp_seg)
  if _tr((1.0 if L_k1 >= v_wp_n else 0.0)):
    v_wp_b = (_mget(v_wp_sr + 0.0) + v_wp_lw)
    v_wp_tb = (_mget(v_wp_tg + 0.0) + v_wp_lw)
    _t3120 = v_wp_tb
  else:
    v_wp_b = _mget(v_wp_sr + L_k1)
    v_wp_tb = _mget(v_wp_tg + L_k1)
    _t3120 = v_wp_tb
  _t3121 = (v_wp_b - v_wp_a)
  _t3122 = max(1.0, _t3121)
  v_wp_lsrc = _t3122
  _t3123 = (v_wp_tb - v_wp_ta)
  _t3124 = max(1.0, _t3123)
  v_wp_lout = _t3124
  _t3125 = (v_srate * 0.01)
  _t3126 = v_wp_lsrc
  _t3127 = v_wp_lout
  _t3128 = min(_t3126, _t3127)
  _t3129 = (0.5 * _t3128)
  _t3130 = min(_t3125, _t3129)
  _t3131 = _t3130
  _t3132 = _floor(_t3131)
  v_wp_atk = _t3132
  _t3133 = (v_wp_lout - v_wp_lsrc)
  _t3134 = abs(_t3133)
  v_wp_cp = (1.0 if _t3134 <= 1.0 else 0.0)
  _t3137 = (v_wp_lout - v_wp_atk)
  _t3135 = (v_wp_lsrc - v_wp_atk)
  _t3136 = max(1.0, _t3135)
  v_wp_rr = _div(_t3137, _t3136)
  _t3138 = (v_srate * 0.02)
  _t3139 = ((v_wp_lout - v_wp_atk) * 0.5)
  _t3140 = min(_t3138, _t3139)
  _t3141 = _t3140
  _t3142 = max(32.0, _t3141)
  _t3143 = _t3142
  _t3144 = _floor(_t3143)
  v_wp_hop = _t3144
  v_wp_gn = (v_wp_hop * 2.0)
  v_wp_j = 0.0
  v_wp_pr = 0.0
  _t3145 = (v_srate * 0.003)
  _t3146 = ((v_wp_lout - v_wp_atk) * 0.25)
  _t3147 = min(_t3145, _t3146)
  _t3148 = _t3147
  _t3149 = max(1.0, _t3148)
  _t3150 = _t3149
  _t3151 = _floor(_t3150)
  v_wp_xn = _t3151
  return v_wp_xn

def f_wp_seg_fill():
  global v_wp_a, v_wp_atk, v_wp_cp, v_wp_lout, v_wp_sl, v_wp_srr, v_wp_ta, v_wp_tl, v_wp_trr
  L_t = 0.0
  L_i = 0.0
  L_s = 0.0
  L_i = 0.0
  if _tr(v_wp_cp):
    _t3152 = v_wp_lout
  else:
    _t3152 = v_wp_atk
  for _t3153 in range(max(0, int(_t3152))):
    _t3154 = (v_wp_ta + L_i)
    _t3155 = f_wp_ix(_t3154)
    L_t = _t3155
    _t3156 = (v_wp_a + L_i)
    _t3157 = f_wp_ix(_t3156)
    L_s = _t3157
    _t3158 = _ix(v_wp_tl + L_t)
    _t3159 = _mget(v_wp_sl + L_s)
    _mset(_t3158, _t3159)
    _t3160 = _ix(v_wp_trr + L_t)
    _t3161 = _mget(v_wp_srr + L_s)
    _mset(_t3160, _t3161)
    L_i = (L_i + 1.0)
  if _tr((0.0 if _tr(v_wp_cp) else 1.0)):
    for _t3163 in range(max(0, int((v_wp_lout - v_wp_atk)))):
      _t3164 = (v_wp_ta + L_i)
      _t3165 = f_wp_ix(_t3164)
      L_t = _t3165
      _t3166 = _ix(v_wp_tl + L_t)
      _t3167 = 0.0
      _mset(_t3166, _t3167)
      _t3168 = _ix(v_wp_trr + L_t)
      _t3169 = 0.0
      _mset(_t3168, _t3169)
      L_i = (L_i + 1.0)
    _t3162 = 0.0
  else:
    _t3162 = 0.0
  return v_wp_lout

def f_wp_grain():
  global v_srate, v_wp_a, v_wp_atk, v_wp_b, v_wp_gn, v_wp_hop, v_wp_j, v_wp_pr, v_wp_rr, v_wp_sl, v_wp_srr, v_wp_ss, v_wp_ta, v_wp_tb, v_wp_tl, v_wp_trr
  L_os = 0.0
  L_ri = 0.0
  L_de = 0.0
  L_bd = 0.0
  L_bs = 0.0
  L_x = 0.0
  L_c = 0.0
  L_p0 = 0.0
  L_p1 = 0.0
  L_n = 0.0
  L_t = 0.0
  L_w = 0.0
  L_s = 0.0
  L_lo = 0.0
  L_hi = 0.0
  L_tw = 0.0
  L_cost = 0.0
  L_os = (((v_wp_ta + v_wp_atk) - v_wp_hop) + (v_wp_j * v_wp_hop))
  _t3170 = (((v_wp_a + v_wp_atk) + _div((L_os - (v_wp_ta + v_wp_atk)), v_wp_rr)) + 0.5)
  _t3171 = _floor(_t3170)
  L_ri = _t3171
  L_de = 0.0
  L_cost = v_wp_gn
  if _tr((1.0 if v_wp_j > 0.0 else 0.0)):
    _t3173 = (v_srate * 0.005)
    _t3174 = _floor(_t3173)
    L_tw = _t3174
    L_bs = (-1000000000.0)
    L_bd = 0.0
    L_de = (0.0 - L_tw)
    _t3175 = 0
    while True:
      if not _tr((1.0 if L_de <= L_tw else 0.0)): break
      L_c = 0.0
      L_x = 0.0
      _t3176 = 0
      while True:
        if not _tr((1.0 if L_x < v_wp_hop else 0.0)): break
        _t3177 = ((v_wp_pr + v_wp_hop) + L_x)
        _t3178 = f_wp_ix(_t3177)
        L_p0 = _t3178
        _t3179 = ((L_ri + L_de) + L_x)
        _t3180 = f_wp_ix(_t3179)
        L_p1 = _t3180
        L_c = (L_c + ((_mget(v_wp_sl + L_p0) + _mget(v_wp_srr + L_p0)) * (_mget(v_wp_sl + L_p1) + _mget(v_wp_srr + L_p1))))
        L_x = (L_x + 8.0)
        _t3176 += 1
        if _t3176 > 1000000: break
      if _tr((1.0 if L_c > L_bs else 0.0)):
        L_bs = L_c
        L_bd = L_de
        _t3181 = L_bd
      else:
        _t3181 = 0.0
      L_de = (L_de + 3.0)
      _t3175 += 1
      if _t3175 > 1000000: break
    L_de = L_bd
    L_cost = (L_cost + (_div((2.0 * L_tw), 3.0) * _div(v_wp_hop, 8.0)))
    _t3172 = L_cost
  else:
    _t3172 = 0.0
  _t3182 = L_de
  _t3185 = v_wp_b
  _t3183 = (v_srate * 0.002)
  _t3184 = _floor(_t3183)
  _t3189 = ((_t3185 - _t3184) - L_ri)
  _t3186 = v_wp_gn
  _t3187 = (v_wp_tb - L_os)
  _t3188 = min(_t3186, _t3187)
  _t3190 = (_t3189 - (_t3188 - 1.0))
  _t3191 = min(_t3182, _t3190)
  L_de = _t3191
  L_ri = (L_ri + L_de)
  v_wp_pr = L_ri
  L_lo = (v_wp_ta + v_wp_atk)
  L_hi = v_wp_tb
  L_n = 0.0
  for _t3192 in range(max(0, int(v_wp_gn))):
    L_t = (L_os + L_n)
    _t3193 = 1.0 if _tr((1.0 if L_t >= L_lo else 0.0)) else 0.0
    if _t3193:
      _t3193 = 1.0 if _tr((1.0 if L_t < L_hi else 0.0)) else 0.0
    if _tr(_t3193):
      _t3195 = _div(((2.0 * 3.141592653589793) * L_n), v_wp_gn)
      _t3196 = math.cos(_t3195)
      L_w = (0.5 - (0.5 * _t3196))
      L_s = (L_ri + L_n)
      if _tr((1.0 if L_s >= v_wp_b else 0.0)):
        _t3201 = (v_wp_b - 1.0)
        _t3200 = (L_s - v_wp_b)
        _t3198 = v_wp_hop
        _t3199 = max(1.0, _t3198)
        L_s = (_t3201 - _mod(_t3200, _t3199))
        _t3197 = L_s
      else:
        _t3197 = 0.0
      _t3202 = L_s
      _t3203 = f_wp_ix(_t3202)
      L_s = _t3203
      _t3204 = L_t
      _t3205 = f_wp_ix(_t3204)
      L_t = _t3205
      _t3206 = _ix(v_wp_tl + L_t)
      _t3207 = (_mget(_t3206) + (L_w * _mget(v_wp_sl + L_s)))
      _mset(_t3206, _t3207)
      _t3208 = _ix(v_wp_trr + L_t)
      _t3209 = (_mget(_t3208) + (L_w * _mget(v_wp_srr + L_s)))
      _mset(_t3208, _t3209)
      _t3194 = _t3209
    else:
      _t3194 = 0.0
    L_n = (L_n + 1.0)
  v_wp_j = (v_wp_j + 1.0)
  if _tr((1.0 if (L_os + v_wp_hop) >= v_wp_tb else 0.0)):
    v_wp_ss = 2.0
    _t3210 = v_wp_ss
  else:
    _t3210 = 0.0
  return L_cost

def f_wp_seg_join():
  global v_wp_a, v_wp_atk, v_wp_b, v_wp_sl, v_wp_srr, v_wp_ta, v_wp_tb, v_wp_tl, v_wp_trr, v_wp_xn
  L_i = 0.0
  L_t = 0.0
  L_k = 0.0
  L_s = 0.0
  L_i = 0.0
  for _t3211 in range(max(0, int(v_wp_xn))):
    L_k = _div((L_i + 1.0), (v_wp_xn + 1.0))
    _t3212 = ((v_wp_ta + v_wp_atk) + L_i)
    _t3213 = f_wp_ix(_t3212)
    L_t = _t3213
    _t3214 = ((v_wp_a + v_wp_atk) + L_i)
    _t3215 = f_wp_ix(_t3214)
    L_s = _t3215
    _t3216 = _ix(v_wp_tl + L_t)
    _t3217 = ((_mget(v_wp_tl + L_t) * L_k) + (_mget(v_wp_sl + L_s) * (1.0 - L_k)))
    _mset(_t3216, _t3217)
    _t3218 = _ix(v_wp_trr + L_t)
    _t3219 = ((_mget(v_wp_trr + L_t) * L_k) + (_mget(v_wp_srr + L_s) * (1.0 - L_k)))
    _mset(_t3218, _t3219)
    L_i = (L_i + 1.0)
  L_i = 0.0
  for _t3220 in range(max(0, int(v_wp_xn))):
    L_k = _div((L_i + 1.0), (v_wp_xn + 1.0))
    _t3221 = ((v_wp_tb - 1.0) - L_i)
    _t3222 = f_wp_ix(_t3221)
    L_t = _t3222
    _t3223 = ((v_wp_b - 1.0) - L_i)
    _t3224 = f_wp_ix(_t3223)
    L_s = _t3224
    _t3225 = _ix(v_wp_tl + L_t)
    _t3226 = ((_mget(v_wp_tl + L_t) * L_k) + (_mget(v_wp_sl + L_s) * (1.0 - L_k)))
    _mset(_t3225, _t3226)
    _t3227 = _ix(v_wp_trr + L_t)
    _t3228 = ((_mget(v_wp_trr + L_t) * L_k) + (_mget(v_wp_srr + L_s) * (1.0 - L_k)))
    _mset(_t3227, _t3228)
    L_i = (L_i + 1.0)
  return (v_wp_xn * 2.0)

def f_wp_render_step(L_bud):
  global v_wp_cp, v_wp_n, v_wp_phase, v_wp_seg, v_wp_ss
  L_used = 0.0
  L_used = 0.0
  _t3229 = 0
  while True:
    _t3230 = 1.0 if _tr((1.0 if L_used < L_bud else 0.0)) else 0.0
    if _t3230:
      _t3230 = 1.0 if _tr((1.0 if abs(v_wp_phase - 4.0) < 0.00001 else 0.0)) else 0.0
    if not _tr(_t3230): break
    if _tr((1.0 if v_wp_seg >= v_wp_n else 0.0)):
      v_wp_phase = 5.0
      _t3231 = v_wp_phase
    else:
      if _tr((1.0 if abs(v_wp_ss - 0.0) < 0.00001 else 0.0)):
        _t3233 = f_wp_seg_init()
        _t3234 = f_wp_seg_fill()
        L_used = (L_used + _t3234)
        if _tr(v_wp_cp):
          _t3235 = 3.0
        else:
          _t3235 = 1.0
        v_wp_ss = _t3235
        _t3232 = v_wp_ss
      else:
        if _tr((1.0 if abs(v_wp_ss - 1.0) < 0.00001 else 0.0)):
          _t3237 = f_wp_grain()
          L_used = (L_used + _t3237)
          _t3236 = L_used
        else:
          if _tr((1.0 if abs(v_wp_ss - 2.0) < 0.00001 else 0.0)):
            _t3239 = f_wp_seg_join()
            L_used = (L_used + _t3239)
            v_wp_ss = 3.0
            _t3238 = v_wp_ss
          else:
            v_wp_seg = (v_wp_seg + 1.0)
            v_wp_ss = 0.0
            _t3238 = v_wp_ss
          _t3236 = _t3238
        _t3232 = _t3236
      _t3231 = _t3232
    _t3229 += 1
    if _t3229 > 1000000: break
  return 0.0

def f_wp_tick():
  global v_active_history_idx, v_an_after_wp, v_ana_end, v_ana_k, v_ana_max_peak, v_analysing, v_cand_n, v_cm_active, v_dirty_len, v_dt_b1, v_dt_b2, v_dt_eh, v_dt_el, v_dt_em, v_dt_gl, v_dt_hc, v_dt_pk, v_dt_tr, v_dv_f, v_dv_hold, v_dv_s, v_dv_trk, v_hist_len, v_hist_redo, v_hist_undo, v_history_count, v_history_head, v_length, v_max_history, v_odf_hop, v_samplesblock, v_single_buf_len, v_slicer_src, v_srate, v_src_auto, v_state, v_sync_hard_resync, v_warp_on, v_wp_busy, v_wp_cb, v_wp_ci, v_wp_free, v_wp_from, v_wp_hr, v_wp_len, v_wp_live, v_wp_mk, v_wp_mn, v_wp_n, v_wp_orig, v_wp_phase, v_wp_prev_on, v_wp_pub, v_wp_rerender, v_wp_ri, v_wp_scan, v_wp_sig, v_wp_sig_job, v_wp_sig_seen, v_wp_sig_t, v_wp_sl, v_wp_srr, v_wp_tgt, v_wp_tl, v_wp_trr, v_wp_wl, v_wp_wsl, v_xf_on
  L_on = 0.0
  L_sig = 0.0
  L_now = 0.0
  L_nx = 0.0
  L_cp = 0.0
  _t3240 = _time()
  L_now = _t3240
  _t3243 = 1.0 if _tr(v_wp_live) else 0.0
  if _t3243:
    _t3243 = 1.0 if _tr((0.0 if _tr(v_wp_busy) else 1.0)) else 0.0
  _t3242 = 1.0 if _tr(_t3243) else 0.0
  if _t3242:
    _t3242 = 1.0 if _tr((1.0 if abs(v_active_history_idx - v_wp_wsl) < 0.00001 else 0.0)) else 0.0
  _t3241 = 1.0 if _tr(_t3242) else 0.0
  if _t3241:
    _t3241 = 1.0 if _tr((1.0 if abs(v_length - v_wp_len) < 0.00001 else 0.0)) else 0.0
  L_on = _t3241
  _t3245 = 1.0 if _tr(v_wp_live) else 0.0
  if _t3245:
    _t3245 = 1.0 if _tr((0.0 if _tr(v_wp_busy) else 1.0)) else 0.0
  _t3244 = 1.0 if _tr(_t3245) else 0.0
  if _t3244:
    _t3244 = 1.0 if _tr((0.0 if abs(L_on - v_wp_prev_on) < 0.00001 else 1.0)) else 0.0
  if _tr(_t3244):
    v_warp_on = L_on
    v_warp_on = v_warp_on
    _t3246 = v_warp_on
  else:
    _t3246 = 0.0
  _t3247 = f_wp_signature()
  L_sig = _t3247
  if _tr((0.0 if abs(L_sig - v_wp_sig_seen) < 0.00001 else 1.0)):
    v_wp_sig_seen = L_sig
    v_wp_sig_t = (L_now + 0.25)
    _t3248 = v_wp_sig_t
  else:
    _t3248 = 0.0
  _t3252 = 1.0 if _tr((1.0 if abs(v_state - 0.0) < 0.00001 else 0.0)) else 0.0
  if not _t3252:
    _t3252 = 1.0 if _tr((1.0 if abs(v_state - 2.0) < 0.00001 else 0.0)) else 0.0
  _t3251 = 1.0 if _tr(_t3252) else 0.0
  if not _t3251:
    _t3251 = 1.0 if _tr((1.0 if abs(v_state - 7.0) < 0.00001 else 0.0)) else 0.0
  _t3250 = 1.0 if _tr(_t3251) else 0.0
  if _t3250:
    _t3250 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
  _t3249 = 1.0 if _tr(_t3250) else 0.0
  if _t3249:
    _t3249 = 1.0 if _tr((0.0 if _tr(v_cm_active) else 1.0)) else 0.0
  v_wp_free = _t3249
  if _tr(v_wp_busy):
    _t3256 = 1.0 if _tr((0.0 if abs(v_length - v_wp_len) < 0.00001 else 1.0)) else 0.0
    if not _t3256:
      _t3257 = 1.0 if _tr((1.0 if v_wp_phase <= 5.0 else 0.0)) else 0.0
      if _t3257:
        _t3257 = 1.0 if _tr((0.0 if abs(v_active_history_idx - v_wp_from) < 0.00001 else 1.0)) else 0.0
      _t3256 = 1.0 if _tr(_t3257) else 0.0
    _t3255 = 1.0 if _tr(_t3256) else 0.0
    if not _t3255:
      _t3255 = 1.0 if _tr((1.0 if abs(v_state - 1.0) < 0.00001 else 0.0)) else 0.0
    _t3254 = 1.0 if _tr(_t3255) else 0.0
    if not _t3254:
      _t3258 = 1.0 if _tr((1.0 if v_state >= 3.0 else 0.0)) else 0.0
      if _t3258:
        _t3258 = 1.0 if _tr((1.0 if v_state <= 6.0 else 0.0)) else 0.0
      _t3254 = 1.0 if _tr(_t3258) else 0.0
    if _tr(_t3254):
      _t3260 = f_wp_abort()
      _t3259 = _t3260
    else:
      _t3259 = 0.0
    _t3253 = _t3259
  else:
    _t3253 = 0.0
  _t3262 = 1.0 if _tr(v_wp_busy) else 0.0
  if _t3262:
    _t3262 = 1.0 if _tr((1.0 if v_warp_on < 0.5 else 0.0)) else 0.0
  _t3261 = 1.0 if _tr(_t3262) else 0.0
  if _t3261:
    _t3263 = 1.0 if _tr((1.0 if v_wp_phase <= 4.0 else 0.0)) else 0.0
    if not _t3263:
      _t3263 = 1.0 if _tr((1.0 if abs(v_wp_phase - 6.0) < 0.00001 else 0.0)) else 0.0
    _t3261 = 1.0 if _tr(_t3263) else 0.0
  if _tr(_t3261):
    _t3265 = f_wp_abort()
    _t3264 = _t3265
  else:
    _t3264 = 0.0
  _t3267 = 1.0 if _tr(v_an_after_wp) else 0.0
  if _t3267:
    _t3267 = 1.0 if _tr((0.0 if _tr(v_wp_scan) else 1.0)) else 0.0
  _t3266 = 1.0 if _tr(_t3267) else 0.0
  if _t3266:
    _t3266 = 1.0 if _tr((0.0 if _tr(v_analysing) else 1.0)) else 0.0
  if _tr(_t3266):
    v_an_after_wp = 0.0
    _t3269 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
    if _t3269:
      _t3270 = 1.0 if _tr((1.0 if abs(v_slicer_src - 1.0) < 0.00001 else 0.0)) else 0.0
      if _t3270:
        _t3270 = 1.0 if _tr((0.0 if _tr(v_src_auto) else 1.0)) else 0.0
      _t3269 = 1.0 if _tr((0.0 if _tr(_t3270) else 1.0)) else 0.0
    if _tr(_t3269):
      _t3272 = f_start_analysis_ex(1.0)
      _t3271 = _t3272
    else:
      _t3271 = 0.0
    _t3268 = _t3271
  else:
    _t3268 = 0.0
  if _tr(v_wp_busy):
    if _tr((1.0 if abs(v_wp_phase - 1.0) < 0.00001 else 0.0)):
      _t3275 = 1.0 if _tr((0.0 if _tr(v_analysing) else 1.0)) else 0.0
      if _t3275:
        _t3275 = 1.0 if _tr((0.0 if _tr(v_cm_active) else 1.0)) else 0.0
      if _tr(_t3275):
        v_wp_scan = 1.0
        v_ana_k = (0.0 - (v_odf_hop * 40.0))
        _t3277 = v_length
        _t3278 = _floor(_t3277)
        v_ana_end = _t3278
        v_cand_n = 0.0
        v_dv_f = 0.0
        v_dv_s = 0.0
        v_dv_hold = 0.0
        v_dv_trk = 0.0
        v_ana_max_peak = 0.0001
        v_dt_b1 = 0.0
        v_dt_b2 = 0.0
        v_dt_el = 0.0
        v_dt_em = 0.0
        v_dt_eh = 0.0
        v_dt_gl = (-1.0)
        v_dt_hc = 0.0
        v_dt_tr = 0.0
        v_dt_pk = 0.0
        v_analysing = 1.0
        v_wp_phase = 2.0
        _t3276 = v_wp_phase
      else:
        _t3276 = 0.0
      _t3274 = _t3276
    else:
      if _tr((1.0 if abs(v_wp_phase - 3.0) < 0.00001 else 0.0)):
        L_cp = 0.0
        _t3280 = 0
        while True:
          _t3281 = 1.0 if _tr((1.0 if L_cp < 24.0 else 0.0)) else 0.0
          if _t3281:
            _t3281 = 1.0 if _tr((1.0 if v_wp_ri < v_wp_mn else 0.0)) else 0.0
          if not _tr(_t3281): break
          _t3282 = _ix(v_wp_mk + v_wp_ri)
          _t3285 = _mget(v_wp_mk + v_wp_ri)
          _t3283 = (v_srate * 0.001)
          _t3284 = _floor(_t3283)
          _t3286 = (_t3285 - _t3284)
          _t3287 = max(0.0, _t3286)
          _t3288 = _t3287
          _t3289 = f_odf_refine(_t3288)
          _t3290 = _t3289
          _mset(_t3282, _t3290)
          v_wp_ri = (v_wp_ri + 1.0)
          L_cp = (L_cp + 1.0)
          _t3280 += 1
          if _t3280 > 1000000: break
        if _tr((1.0 if v_wp_ri >= v_wp_mn else 0.0)):
          _t3292 = f_wp_targets()
          v_wp_ci = 0.0
          v_wp_phase = 6.0
          _t3291 = v_wp_phase
        else:
          _t3291 = 0.0
        _t3279 = _t3291
      else:
        if _tr((1.0 if abs(v_wp_phase - 6.0) < 0.00001 else 0.0)):
          _t3294 = (v_wp_len - v_wp_ci)
          _t3295 = min(262144.0, _t3294)
          L_cp = _t3295
          if _tr((1.0 if L_cp > 0.0 else 0.0)):
            _t3297 = (v_wp_tl + v_wp_ci)
            _t3298 = (v_wp_sl + v_wp_ci)
            _t3299 = L_cp
            _t3300 = _memcpy(_t3297, _t3298, _t3299)
            _t3301 = (v_wp_trr + v_wp_ci)
            _t3302 = (v_wp_srr + v_wp_ci)
            _t3303 = L_cp
            _t3304 = _memcpy(_t3301, _t3302, _t3303)
            v_wp_ci = (v_wp_ci + L_cp)
            _t3296 = v_wp_ci
          else:
            _t3296 = 0.0
          if _tr((1.0 if v_wp_ci >= v_wp_len else 0.0)):
            if _tr((1.0 if v_wp_n > 0.0 else 0.0)):
              v_wp_phase = 4.0
              _t3306 = v_wp_phase
            else:
              v_wp_phase = 5.0
              _t3306 = v_wp_phase
            _t3305 = _t3306
          else:
            _t3305 = 0.0
          _t3293 = _t3305
        else:
          if _tr((1.0 if abs(v_wp_phase - 4.0) < 0.00001 else 0.0)):
            _t3308 = (v_samplesblock * 12.0)
            _t3309 = _floor(_t3308)
            _t3310 = _t3309
            _t3311 = max(4096.0, _t3310)
            _t3312 = _t3311
            _t3313 = f_wp_render_step(_t3312)
            _t3307 = _t3313
          else:
            if _tr((1.0 if abs(v_wp_phase - 5.0) < 0.00001 else 0.0)):
              if _tr(v_wp_rerender):
                _t3316 = v_wp_tgt
                _t3317 = f_switch_history_slot(_t3316)
                _t3318 = (v_srate * 0.01)
                _t3319 = _floor(_t3318)
                _t3320 = _t3319
                _t3321 = f_xf_begin(_t3320, 1.0)
                v_wp_ci = 0.0
                v_wp_phase = 7.0
                _t3315 = v_wp_phase
              else:
                v_history_head = v_wp_tgt
                _t3322 = _ix(v_hist_len + v_wp_tgt)
                _t3323 = v_length
                _mset(_t3322, _t3323)
                _t3324 = v_dirty_len
                _t3325 = v_length
                _t3326 = max(_t3324, _t3325)
                v_dirty_len = _t3326
                _t3327 = (v_hist_undo + 1.0)
                _t3328 = (v_max_history - 1.0)
                _t3329 = min(_t3327, _t3328)
                v_hist_undo = _t3329
                v_hist_redo = 0.0
                v_history_count = (v_hist_undo + 1.0)
                _t3330 = v_wp_tgt
                _t3331 = f_switch_history_slot(_t3330)
                _t3332 = (v_srate * 0.01)
                _t3333 = _floor(_t3332)
                _t3334 = _t3333
                _t3335 = f_xf_begin(_t3334, 1.0)
                v_wp_wsl = v_wp_tgt
                v_wp_busy = 0.0
                v_wp_phase = 0.0
                v_wp_live = 1.0
                v_wp_sig = v_wp_sig_job
                v_wp_prev_on = 1.0
                _t3336 = 1.0 if _tr((1.0 if abs(v_slicer_src - 1.0) < 0.00001 else 0.0)) else 0.0
                if _t3336:
                  _t3336 = 1.0 if _tr((0.0 if _tr(v_src_auto) else 1.0)) else 0.0
                if _tr((0.0 if _tr(_t3336) else 1.0)):
                  _t3338 = f_start_analysis_ex(1.0)
                  _t3337 = _t3338
                else:
                  _t3337 = 0.0
                _t3315 = _t3337
              _t3314 = _t3315
            else:
              if _tr((1.0 if abs(v_wp_phase - 7.0) < 0.00001 else 0.0)):
                if _tr((0.0 if _tr(v_xf_on) else 1.0)):
                  _t3341 = (v_wp_len - v_wp_ci)
                  _t3342 = min(262144.0, _t3341)
                  L_cp = _t3342
                  if _tr((1.0 if L_cp > 0.0 else 0.0)):
                    _t3344 = (v_wp_wl + v_wp_ci)
                    _t3345 = (v_wp_tl + v_wp_ci)
                    _t3346 = L_cp
                    _t3347 = _memcpy(_t3344, _t3345, _t3346)
                    _t3348 = ((v_wp_wl + v_single_buf_len) + v_wp_ci)
                    _t3349 = (v_wp_trr + v_wp_ci)
                    _t3350 = L_cp
                    _t3351 = _memcpy(_t3348, _t3349, _t3350)
                    v_wp_ci = (v_wp_ci + L_cp)
                    _t3343 = v_wp_ci
                  else:
                    _t3343 = 0.0
                  if _tr((1.0 if v_wp_ci >= v_wp_len else 0.0)):
                    _t3353 = v_wp_wsl
                    _t3354 = f_switch_history_slot(_t3353)
                    _t3355 = _ix(v_hist_len + v_wp_wsl)
                    _t3356 = v_length
                    _mset(_t3355, _t3356)
                    v_wp_busy = 0.0
                    v_wp_phase = 0.0
                    v_wp_cb = 0.0
                    v_wp_sig = v_wp_sig_job
                    v_wp_prev_on = 1.0
                    _t3357 = 1.0 if _tr((1.0 if abs(v_slicer_src - 1.0) < 0.00001 else 0.0)) else 0.0
                    if _t3357:
                      _t3357 = 1.0 if _tr((0.0 if _tr(v_src_auto) else 1.0)) else 0.0
                    if _tr((0.0 if _tr(_t3357) else 1.0)):
                      _t3359 = f_start_analysis_ex(1.0)
                      _t3358 = _t3359
                    else:
                      _t3358 = 0.0
                    _t3352 = _t3358
                  else:
                    _t3352 = 0.0
                  _t3340 = _t3352
                else:
                  _t3340 = 0.0
                _t3339 = _t3340
              else:
                _t3339 = 0.0
              _t3314 = _t3339
            _t3307 = _t3314
          _t3293 = _t3307
        _t3279 = _t3293
      _t3274 = _t3279
    _t3273 = _t3274
  else:
    _t3361 = 1.0 if _tr(v_wp_live) else 0.0
    if _t3361:
      _t3361 = 1.0 if _tr((1.0 if abs(v_active_history_idx - v_wp_wsl) < 0.00001 else 0.0)) else 0.0
    _t3360 = 1.0 if _tr(_t3361) else 0.0
    if _t3360:
      _t3360 = 1.0 if _tr((1.0 if abs(v_length - v_wp_len) < 0.00001 else 0.0)) else 0.0
    L_on = _t3360
    _t3363 = 1.0 if _tr((1.0 if v_warp_on >= 0.5 else 0.0)) else 0.0
    if _t3363:
      _t3363 = 1.0 if _tr((0.0 if _tr(L_on) else 1.0)) else 0.0
    _t3362 = 1.0 if _tr(_t3363) else 0.0
    if _t3362:
      _t3362 = 1.0 if _tr(v_wp_free) else 0.0
    if _tr(_t3362):
      _t3368 = 1.0 if _tr(v_wp_live) else 0.0
      if _t3368:
        _t3368 = 1.0 if _tr((1.0 if abs(v_active_history_idx - v_wp_orig) < 0.00001 else 0.0)) else 0.0
      _t3367 = 1.0 if _tr(_t3368) else 0.0
      if _t3367:
        _t3367 = 1.0 if _tr((1.0 if v_hist_redo >= 1.0 else 0.0)) else 0.0
      _t3366 = 1.0 if _tr(_t3367) else 0.0
      if _t3366:
        _t3366 = 1.0 if _tr((1.0 if abs(v_length - v_wp_len) < 0.00001 else 0.0)) else 0.0
      _t3365 = 1.0 if _tr(_t3366) else 0.0
      if _t3365:
        _t3365 = 1.0 if _tr((1.0 if abs(L_sig - v_wp_sig) < 0.00001 else 0.0)) else 0.0
      if _tr(_t3365):
        v_wp_hr = v_sync_hard_resync
        _t3370 = f_redo_state()
        v_sync_hard_resync = v_wp_hr
        _t3371 = (v_srate * 0.01)
        _t3372 = _floor(_t3371)
        _t3373 = _t3372
        _t3374 = f_xf_begin(_t3373, 1.0)
        v_wp_prev_on = 1.0
        _t3375 = 1.0 if _tr((1.0 if abs(v_slicer_src - 1.0) < 0.00001 else 0.0)) else 0.0
        if _t3375:
          _t3375 = 1.0 if _tr((0.0 if _tr(v_src_auto) else 1.0)) else 0.0
        if _tr((0.0 if _tr(_t3375) else 1.0)):
          _t3377 = f_start_analysis_ex(1.0)
          _t3376 = _t3377
        else:
          _t3376 = 0.0
        _t3369 = _t3376
      else:
        if _tr((1.0 if L_now >= v_wp_sig_t else 0.0)):
          v_wp_live = 0.0
          v_wp_orig = v_active_history_idx
          v_wp_from = v_wp_orig
          v_wp_len = v_length
          v_wp_tgt = _mod((v_wp_orig + 1.0), v_max_history)
          v_wp_rerender = 0.0
          _t3379 = v_wp_orig
          _t3380 = f_wp_slot_l(_t3379)
          v_wp_sl = _t3380
          v_wp_srr = (v_wp_sl + v_single_buf_len)
          _t3381 = v_wp_tgt
          _t3382 = f_wp_slot_l(_t3381)
          v_wp_tl = _t3382
          v_wp_trr = (v_wp_tl + v_single_buf_len)
          v_wp_sig_job = L_sig
          v_wp_busy = 1.0
          v_wp_phase = 1.0
          _t3378 = v_wp_phase
        else:
          _t3378 = 0.0
        _t3369 = _t3378
      _t3364 = _t3369
    else:
      _t3383 = 1.0 if _tr((1.0 if v_warp_on < 0.5 else 0.0)) else 0.0
      if _t3383:
        _t3383 = 1.0 if _tr(L_on) else 0.0
      if _tr(_t3383):
        v_wp_hr = v_sync_hard_resync
        _t3385 = f_undo_state()
        v_sync_hard_resync = v_wp_hr
        _t3386 = (v_srate * 0.01)
        _t3387 = _floor(_t3386)
        _t3388 = _t3387
        _t3389 = f_xf_begin(_t3388, 1.0)
        v_wp_prev_on = 0.0
        _t3390 = 1.0 if _tr((1.0 if abs(v_slicer_src - 1.0) < 0.00001 else 0.0)) else 0.0
        if _t3390:
          _t3390 = 1.0 if _tr((0.0 if _tr(v_src_auto) else 1.0)) else 0.0
        if _tr((0.0 if _tr(_t3390) else 1.0)):
          _t3392 = f_start_analysis_ex(1.0)
          _t3391 = _t3392
        else:
          _t3391 = 0.0
        _t3384 = _t3391
      else:
        _t3395 = 1.0 if _tr(L_on) else 0.0
        if _t3395:
          _t3395 = 1.0 if _tr((0.0 if abs(L_sig - v_wp_sig) < 0.00001 else 1.0)) else 0.0
        _t3394 = 1.0 if _tr(_t3395) else 0.0
        if _t3394:
          _t3394 = 1.0 if _tr((1.0 if L_now >= v_wp_sig_t else 0.0)) else 0.0
        _t3393 = 1.0 if _tr(_t3394) else 0.0
        if _t3393:
          _t3393 = 1.0 if _tr(v_wp_free) else 0.0
        if _tr(_t3393):
          L_nx = _mod((v_wp_wsl + 1.0), v_max_history)
          _t3397 = 1.0 if _tr((0.0 if abs(L_nx - v_wp_orig) < 0.00001 else 1.0)) else 0.0
          if _t3397:
            _t3397 = 1.0 if _tr((1.0 if v_max_history >= 3.0 else 0.0)) else 0.0
          if _tr(_t3397):
            if _tr((1.0 if v_hist_undo >= (v_max_history - 1.0) else 0.0)):
              v_hist_undo = (v_max_history - 2.0)
              v_history_count = (v_hist_undo + 1.0)
              _t3399 = v_history_count
            else:
              _t3399 = 0.0
            v_wp_from = v_wp_wsl
            v_wp_tgt = L_nx
            v_wp_rerender = 1.0
            _t3400 = v_wp_orig
            _t3401 = f_wp_slot_l(_t3400)
            v_wp_sl = _t3401
            v_wp_srr = (v_wp_sl + v_single_buf_len)
            _t3402 = v_wp_tgt
            _t3403 = f_wp_slot_l(_t3402)
            v_wp_tl = _t3403
            v_wp_trr = (v_wp_tl + v_single_buf_len)
            _t3404 = v_wp_wsl
            _t3405 = f_wp_slot_l(_t3404)
            v_wp_wl = _t3405
            v_wp_sig_job = L_sig
            v_wp_busy = 1.0
            v_wp_ri = v_wp_mn
            v_wp_phase = 3.0
            _t3398 = v_wp_phase
          else:
            _t3398 = 0.0
          _t3396 = _t3398
        else:
          _t3396 = 0.0
        _t3384 = _t3396
      _t3364 = _t3384
    _t3273 = _t3364
  _t3407 = 1.0 if _tr(v_wp_live) else 0.0
  if _t3407:
    _t3407 = 1.0 if _tr((1.0 if abs(v_active_history_idx - v_wp_wsl) < 0.00001 else 0.0)) else 0.0
  _t3406 = 1.0 if _tr(_t3407) else 0.0
  if _t3406:
    _t3406 = 1.0 if _tr((1.0 if abs(v_length - v_wp_len) < 0.00001 else 0.0)) else 0.0
  L_on = _t3406
  if _tr((0.0 if _tr(v_wp_busy) else 1.0)):
    v_wp_prev_on = L_on
    _t3408 = v_wp_prev_on
  else:
    _t3408 = 0.0
  if _tr(v_wp_busy):
    _t3409 = 2.0
  else:
    _t3409 = L_on
  v_wp_pub = _t3409
  return v_wp_pub

def sec_init():
  global v_ab_len, v_ab_nb, v_ab_ts, v_acc_cur, v_acc_cur_dirty, v_acc_end, v_acc_hi, v_acc_len, v_acc_lo, v_acc_mode, v_acc_ok, v_acc_set0, v_acc_set1, v_acc_size, v_acc_wmin, v_acc_wrep, v_active_control, v_active_history_idx, v_active_part, v_an_after_wp, v_an_dmin, v_an_done, v_an_exit_pending, v_an_gap, v_an_gapm, v_an_keep, v_an_n, v_an_ne, v_an_nr, v_an_ns, v_an_prev_hist, v_an_prev_state, v_an_win_last, v_an_win_pend, v_an_win_t, v_an_wrap_pending, v_ana_end, v_ana_env, v_ana_k, v_ana_last_trig, v_ana_max_peak, v_ana_min_dist, v_ana_mode, v_ana_win_size, v_analysing, v_ar_att, v_ar_cnt, v_ar_dn, v_ar_hold, v_ar_in, v_ar_lp, v_ar_rel, v_ar_up, v_auto_above_prev, v_auto_on, v_auto_rep_active, v_auto_rep_hold_counter, v_available_slots, v_base, v_base_backup_l, v_base_backup_r, v_base_len_part1, v_base_len_part2, v_base_len_part3, v_base_loop_length, v_br_bg_e, v_br_bg_pos, v_br_bg_s, v_br_mix, v_br_mix_s, v_br_on, v_br_saved_start, v_br_saved_width, v_br_suppress_an, v_buf_len, v_buf_part1_l, v_buf_part1_r, v_buf_part2_l, v_buf_part2_r, v_buf_part3_l, v_buf_part3_r, v_can_sync, v_cand_k, v_cand_max, v_cand_n, v_cand_ok, v_cand_p, v_cand_s, v_cand_v, v_cl_a, v_cl_act, v_cl_center, v_cl_g, v_cl_latt, v_cl_lc, v_cl_ld, v_cl_lg, v_cl_lh, v_cl_li, v_cl_lk, v_cl_lrel, v_cl_lth, v_cl_max, v_cl_mem, v_cl_n, v_cl_out_l, v_cl_out_r, v_cl_stride, v_cl_timer, v_clk_cyc, v_clk_cyc1, v_clk_cyc2, v_clk_cyc3, v_clk_len_ref, v_cloud_center_draw, v_cloud_chaos, v_cloud_density, v_cloud_lfo_depth, v_cloud_lfo_phase, v_cloud_lfo_rate, v_cloud_lfo_shape, v_cloud_mix, v_cloud_on, v_cloud_pitch_spread, v_cloud_pos_mode, v_cloud_pos_pct, v_cloud_spread, v_clr_long_pressed, v_clr_press_time, v_cm_active, v_cm_dir, v_cm_hi, v_cm_k, v_cm_lo, v_cm_mode, v_cm_sb, v_co_p, v_co_rec, v_current_slice_pitch, v_delay_buf_l, v_delay_buf_r, v_delay_idx, v_delay_len, v_dens_bag, v_dens_bag_i, v_dens_carry, v_dens_first, v_dens_force, v_dens_g, v_dens_last_occ, v_dens_len, v_dens_len_f, v_dens_minlen, v_dens_next_on, v_dens_prev_state, v_dens_rt, v_dens_seg, v_dens_slew, v_dens_slot, v_dens_t, v_dens_tgt, v_dens_ton, v_det_cap, v_det_chg, v_det_hold_ms, v_det_rel, v_det_thresh, v_df_a1, v_df_a2, v_df_a3, v_df_a4, v_df_b1, v_df_b2, v_df_b3, v_df_b4, v_df_dl, v_df_dr, v_df_fl, v_df_fr, v_df_lp_l, v_df_lp_r, v_df_mem, v_df_on, v_df_p, v_df_sc, v_dirty_len, v_dr_base, v_dr_blk, v_dr_cnt, v_dr_j, v_dr_l, v_dr_mode, v_dr_t0, v_dr_t1, v_dr_tok, v_dt_b1, v_dt_b2, v_dt_bs, v_dt_cap, v_dt_eh, v_dt_el, v_dt_em, v_dt_gh, v_dt_gl, v_dt_gm, v_dt_hc, v_dt_kb, v_dt_kd, v_dt_mask, v_dt_on, v_dt_pk, v_dt_rg, v_dt_rh, v_dt_ri, v_dt_rl, v_dt_rm, v_dt_th, v_dt_tr, v_dub_g, v_dub_gran, v_dub_gran_prev, v_dub_pan, v_dub_pf, v_dub_pfk, v_dv_a, v_dv_cs, v_dv_f, v_dv_hold, v_dv_j, v_dv_lim, v_dv_m, v_dv_rf, v_dv_s, v_dv_trk, v_dv_trkn, v_ext_noinit, v_flutter_phase, v_frz_center, v_frz_copying, v_frz_i, v_frz_l, v_frz_len, v_frz_max, v_frz_prev, v_frz_r, v_frz_ready, v_gm_bpm, v_gm_pspread_cloud, v_gm_pspread_slicer, v_gm_sampler_armed, v_gm_sampler_pmode, v_gm_sampler_release, v_gm_sampler_root, v_gm_sampler_voices, v_gmem, v_grain_data_size, v_grain_dur, v_grain_mem, v_grain_mix, v_gran_now, v_grid_pending, v_grid_sig, v_grid_sub, v_hist_len, v_hist_mem_start, v_hist_redo, v_hist_undo, v_history_count, v_history_head, v_history_tail, v_hold_samples_left, v_i, v_ih_l, v_ih_mask, v_ih_n, v_ih_r, v_ih_size, v_init_done, v_input_env, v_input_signal_active, v_inst_idx, v_instance_alias, v_instance_id, v_io_e_lock, v_io_w_lock, v_is_normal_playback, v_last_det_h, v_last_det_t, v_last_ghost_pct, v_last_grid_sub, v_last_hold, v_last_link, v_last_loop_quant, v_last_max_sl, v_last_mouse_cap, v_last_mouse_y, v_last_pitch_spread, v_last_preset, v_last_sens, v_last_slicer_mode, v_last_slicer_src, v_last_slicer_step, v_last_slider9, v_last_state_target, v_last_steps, v_lat_samps, v_ld_active, v_ld_base, v_ld_i, v_ld_maxn, v_ld_n, v_ld_part, v_ld_qid, v_ld_ref, v_left_buf, v_len_part1, v_len_part2, v_len_part3, v_length, v_loop_edit_mode, v_loop_pos_pct, v_loop_quant, v_loop_start, v_loop_width, v_lp_mute, v_lut_cos, v_lut_size, v_manual_id, v_master_pos, v_master_pos1, v_master_pos2, v_master_pos3, v_max_grains, v_max_history, v_max_inst, v_max_loop_sec, v_max_slices, v_max_transients, v_max_wgrains, v_maxsl_f, v_mclk_cyc, v_mclk_len, v_mclk_len_prev, v_mclk_pos, v_mclk_valid, v_mem_budget, v_ml_cool, v_ml_fwd_free, v_ml_ok, v_mult_len, v_mute_g, v_odf2_mem, v_odf_a_lo, v_odf_a_mid, v_odf_c_hi, v_odf_c_lo, v_odf_c_mid, v_odf_cnt, v_odf_cs, v_odf_floor, v_odf_hop, v_odf_max_n, v_odf_mem, v_odf_n, v_odf_w, v_old_pos_ptr, v_one_shot_playing, v_one_shot_pp_state, v_param_smooth_coeff, v_part_cloud_on, v_part_link_on, v_part_pingpong, v_part_pitch, v_part_play_mode, v_part_rev, v_part_sep, v_part_sm, v_part_sp, v_part_speed, v_part_sref, v_pd_arm, v_pd_k, v_pd_l, v_pd_prev_l, v_pd_prev_r, v_pd_r, v_peak_in_vu, v_peak_loop_vu, v_peak_out_vu, v_pending_next_state, v_pending_part_switch, v_ping_pong_dir, v_pos, v_preset_cur, v_preset_mem, v_prev_cloud_on, v_prev_in0, v_prev_in1, v_prev_loop_start, v_prev_loop_width, v_prev_normal_playback, v_prev_pingpong_on, v_prev_pitch_ratio_sig, v_prev_play_mode, v_prev_rev_on, v_prev_sm_speed, v_prev_state_for_sync, v_prev_sync_key, v_prev_xcl, v_pslot, v_qs_snap, v_rd_last_g, v_rd_last_l, v_rd_last_p, v_rd_last_pamt, v_rd_last_pan, v_rd_last_r, v_rd_last_st, v_rd_last_we, v_rd_last_ws, v_rd_prev_dur, v_rd_prev_n, v_rd_prev_ok, v_rd_prev_start, v_rd_tmp, v_rd_valid, v_rec_cmd, v_rec_force_free, v_rec_lag_pend, v_rec_ref_id, v_rec_ref_kind, v_rec_ref_len, v_rec_ref_ph, v_rec_start_lag, v_rec_start_time, v_rec_stop_lag, v_replace_fade, v_replace_fade_coeff, v_right_buf, v_rp_cnt, v_rp_part, v_rp_pend, v_rp_tail_on, v_rx_seen, v_sampler_rel_u, v_sampler_release, v_sampler_root, v_sampler_root_f, v_saved_manual_id, v_sel_k, v_sel_n, v_sel_s, v_seq_mem, v_single_buf_len, v_sl_gate, v_sl_hi, v_sl_lo, v_sl_pan_amt, v_sl_pan_k, v_sl_pre_t, v_sl_rec, v_sl_run, v_sl_slew, v_slice_att, v_slice_att_eff_ms, v_slice_att_step, v_slice_decay_ms, v_slice_decay_samples, v_slice_decay_step, v_slice_env, v_slice_hold, v_slice_mute_gate, v_slice_mute_step, v_slice_mute_target, v_slice_pan, v_slice_pitch_mem, v_slicer_current_step, v_slicer_link, v_slicer_mode, v_slicer_pitch_spread, v_slicer_sample_counter, v_slicer_steps, v_slot_size, v_slw_last, v_slx_mix, v_slx_mix_s, v_slx_pos, v_slx_prev, v_smooth_start, v_smooth_width, v_smp_age, v_smp_alloff, v_smp_armed, v_smp_att, v_smp_blk, v_smp_choke_rel, v_smp_ev_i, v_smp_ev_n, v_smp_ev_note, v_smp_ev_off, v_smp_ev_vel, v_smp_evmax, v_smp_g, v_smp_gh, v_smp_kmode, v_smp_l, v_smp_mode, v_smp_nact, v_smp_nv, v_smp_prev_mode, v_smp_quick_rel, v_smp_r, v_smp_rl, v_smp_rr, v_smp_tail, v_smp_voice, v_smp_vs, v_spawn_timer, v_srate, v_st_band, v_st_fft, v_st_fmax, v_st_lag, v_st_n, v_st_nb, v_st_ring, v_st_rp, v_st_win, v_state, v_state_target, v_state_transition_fade, v_steps_f, v_sw_on, v_sw_pos, v_sync_a, v_sync_b, v_sync_c_l, v_sync_c_r, v_sync_c_w, v_sync_hard_resync, v_tape_lpf_l, v_tape_lpf_l_b, v_tape_lpf_l_c, v_tape_lpf_l_d, v_tape_lpf_r, v_tape_lpf_r_b, v_tape_lpf_r_c, v_tape_lpf_r_d, v_target_part, v_target_sync_len, v_trans_count, v_trans_hold_ms, v_trans_mem, v_trans_sens, v_trans_str, v_ui_ab, v_ui_ag, v_ui_ar, v_ui_chg, v_ui_en, v_ui_hov, v_vu_rel, v_wg_el, v_wg_es, v_wg_fade, v_wg_gl, v_wg_gr, v_wg_hop, v_wg_lcur, v_wg_mem, v_wg_prev_n, v_wg_prev_ok, v_wg_prev_src, v_wg_rf, v_wg_stride, v_wg_timer, v_wow_phase, v_wp_busy, v_wp_dd, v_wp_from, v_wp_len, v_wp_live, v_wp_ls, v_wp_lw, v_wp_max, v_wp_mk, v_wp_mn, v_wp_n, v_wp_orig, v_wp_phase, v_wp_prev_on, v_wp_scan, v_wp_sig, v_wp_sig_seen, v_wp_sig_t, v_wp_sr, v_wp_tg, v_wp_tgt, v_wp_wsl, v_wr_off, v_write_ptr, v_x_event, v_x_free, v_x_mode, v_x_ms, v_x_part, v_x_per, v_x_ph_prev, v_xarm, v_xf_eqp, v_xf_g, v_xf_inc, v_xf_k, v_xf_l, v_xf_len_jump, v_xf_len_rs, v_xf_len_slice, v_xf_on, v_xf_p, v_xf_pamt, v_xf_pan, v_xf_r, v_xf_st, v_xf_we, v_xf_ws, v_xfade_coeff, v_xfade_pos_active, v_xfade_pos_count, v_xfade_pos_len
  v_slice_decay_ms = 150.0
  v_ext_noinit = 1.0
  _t3410 = (v_manual_id + 0.5)
  _t3411 = _floor(_t3410)
  v_manual_id = _t3411
  if _tr((1.0 if v_manual_id < 0.0 else 0.0)):
    v_manual_id = 0.0
    _t3412 = v_manual_id
  else:
    if _tr((1.0 if v_manual_id > 8.0 else 0.0)):
      v_manual_id = 8.0
      _t3413 = v_manual_id
    else:
      _t3413 = 0.0
    _t3412 = _t3413
  v_manual_id = v_manual_id
  if _tr((1.0 if v_manual_id > 0.0 else 0.0)):
    _t3414 = v_manual_id
  else:
    _t3414 = 1.0
  v_instance_id = _t3414
  v_instance_alias = v_instance_id
  v_inst_idx = (v_instance_id - 1.0)
  v_max_inst = 8.0
  v_saved_manual_id = v_manual_id
  v_max_loop_sec = 90.0
  v_mem_budget = 12000000.0
  _t3415 = (v_srate * v_max_loop_sec)
  _t3416 = _floor(_t3415)
  _t3417 = _t3416
  _t3418 = _div(v_mem_budget, 30.0)
  _t3419 = _floor(_t3418)
  _t3420 = _t3419
  _t3421 = min(_t3417, _t3420)
  v_single_buf_len = _t3421
  v_buf_len = v_single_buf_len
  v_slot_size = (v_single_buf_len * 2.0)
  v_buf_part1_l = 0.0
  v_buf_part1_r = v_single_buf_len
  v_buf_part2_l = v_slot_size
  v_buf_part2_r = (v_slot_size + v_single_buf_len)
  v_buf_part3_l = (v_slot_size * 2.0)
  v_buf_part3_r = ((v_slot_size * 2.0) + v_single_buf_len)
  v_hist_mem_start = (v_slot_size * 3.0)
  _t3422 = _div((((v_mem_budget - v_hist_mem_start) - v_slot_size) - 20000.0), v_slot_size)
  _t3423 = _floor(_t3422)
  v_available_slots = _t3423
  _t3424 = (v_available_slots + 1.0)
  _t3425 = min(8.0, _t3424)
  _t3426 = _t3425
  _t3427 = max(2.0, _t3426)
  v_max_history = _t3427
  v_base_backup_l = (v_hist_mem_start + ((v_max_history - 1.0) * v_slot_size))
  v_base_backup_r = (v_base_backup_l + v_single_buf_len)
  v_hist_len = ((v_base_backup_r + v_single_buf_len) + 1000.0)
  v_i = 0.0
  for _t3428 in range(max(0, int(16.0))):
    _t3429 = _ix(v_hist_len + v_i)
    _t3430 = 0.0
    _mset(_t3429, _t3430)
    v_i = (v_i + 1.0)
  v_active_part = 1.0
  v_target_part = 1.0
  v_pending_part_switch = 0.0
  v_part_speed = (v_hist_len + 50.0)
  v_part_pitch = (v_part_speed + 3.0)
  v_part_rev = (v_part_pitch + 3.0)
  v_part_pingpong = (v_part_rev + 3.0)
  v_part_play_mode = (v_part_pingpong + 3.0)
  v_part_cloud_on = (v_part_play_mode + 3.0)
  v_part_link_on = (v_part_cloud_on + 3.0)
  v_part_sp = (v_part_link_on + 3.0)
  v_part_sref = (v_part_sp + 3.0)
  v_part_sm = (v_part_sref + 3.0)
  v_part_sep = (v_part_sm + 3.0)
  v_rp_pend = 0.0
  v_rp_cnt = 0.0
  v_rp_part = 0.0
  v_ab_len = (-1.0)
  v_ab_ts = (-1.0)
  v_ab_nb = 4.0
  v_rec_ref_kind = 0.0
  v_rec_ref_id = 0.0
  v_rec_ref_len = 0.0
  v_rec_ref_ph = 0.0
  v_qs_snap = 0.0
  v_mclk_valid = 0.0
  v_mclk_pos = 0.0
  v_mclk_len = 0.0
  v_mclk_len_prev = 0.0
  v_mclk_cyc = 0.0
  v_i = 0.0
  for _t3431 in range(max(0, int(3.0))):
    _t3432 = _ix(v_part_sp + v_i)
    _t3433 = (-1.0)
    _mset(_t3432, _t3433)
    _t3434 = _ix(v_part_sref + v_i)
    _t3435 = 0.0
    _mset(_t3434, _t3435)
    _t3436 = _ix(v_part_sm + v_i)
    _t3437 = 0.0
    _mset(_t3436, _t3437)
    _t3438 = _ix(v_part_sep + v_i)
    _t3439 = 0.0
    _mset(_t3438, _t3439)
    v_i = (v_i + 1.0)
  v_i = 0.0
  for _t3440 in range(max(0, int(3.0))):
    _t3441 = _ix(v_part_speed + v_i)
    _t3442 = 1.0
    _mset(_t3441, _t3442)
    _t3443 = _ix(v_part_pitch + v_i)
    _t3444 = 0.0
    _mset(_t3443, _t3444)
    _t3445 = _ix(v_part_rev + v_i)
    _t3446 = 0.0
    _mset(_t3445, _t3446)
    _t3447 = _ix(v_part_pingpong + v_i)
    _t3448 = 0.0
    _mset(_t3447, _t3448)
    _t3449 = _ix(v_part_play_mode + v_i)
    _t3450 = 0.0
    _mset(_t3449, _t3450)
    _t3451 = _ix(v_part_cloud_on + v_i)
    _t3452 = 0.0
    _mset(_t3451, _t3452)
    _t3453 = _ix(v_part_link_on + v_i)
    _t3454 = 0.0
    _mset(_t3453, _t3454)
    v_i = (v_i + 1.0)
  v_len_part1 = 0.0
  v_len_part2 = 0.0
  v_len_part3 = 0.0
  v_base_len_part1 = 0.0
  v_base_len_part2 = 0.0
  v_base_len_part3 = 0.0
  v_history_head = 0.0
  v_history_tail = 0.0
  v_history_count = 1.0
  v_active_history_idx = 0.0
  v_hist_undo = 0.0
  v_hist_redo = 0.0
  v_dirty_len = 0.0
  v_left_buf = v_buf_part1_l
  v_right_buf = v_buf_part1_r
  v_max_grains = 16.0
  v_grain_data_size = 8.0
  v_grain_mem = (v_part_link_on + 100.0)
  v_max_transients = 256.0
  v_trans_mem = ((v_grain_mem + (v_max_grains * v_grain_data_size)) + 100.0)
  v_seq_mem = ((v_trans_mem + v_max_transients) + 100.0)
  v_slice_pitch_mem = ((v_seq_mem + v_max_transients) + 100.0)
  v_trans_count = 0.0
  v_lut_size = 1024.0
  v_lut_cos = ((v_slice_pitch_mem + v_max_transients) + 100.0)
  v_i = 0.0
  for _t3455 in range(max(0, int(v_lut_size))):
    _t3456 = _ix(v_lut_cos + v_i)
    _t3457 = ((2.0 * 3.141592653589793) * _div(v_i, v_lut_size))
    _t3458 = math.cos(_t3457)
    _t3459 = (0.5 - (0.5 * _t3458))
    _mset(_t3456, _t3459)
    v_i = (v_i + 1.0)
  v_i = 0.0
  for _t3460 in range(max(0, int(v_max_grains))):
    v_base = (v_grain_mem + (v_i * v_grain_data_size))
    _t3461 = _ix(v_base + 0.0)
    _t3462 = 0.0
    _mset(_t3461, _t3462)
    _t3463 = _ix(v_base + 1.0)
    _t3464 = 0.0
    _mset(_t3463, _t3464)
    _t3465 = _ix(v_base + 2.0)
    _t3466 = 0.0
    _mset(_t3465, _t3466)
    _t3467 = _ix(v_base + 3.0)
    _t3468 = (v_srate * 0.1)
    _mset(_t3467, _t3468)
    _t3469 = _ix(v_base + 4.0)
    _t3470 = 0.0
    _mset(_t3469, _t3470)
    _t3471 = _ix(v_base + 5.0)
    _t3472 = 0.0
    _mset(_t3471, _t3472)
    _t3473 = _ix(v_base + 6.0)
    _t3474 = 0.0
    _mset(_t3473, _t3474)
    _t3475 = _ix(v_base + 7.0)
    _t3476 = 0.0
    _mset(_t3475, _t3476)
    v_i = (v_i + 1.0)
  v_grain_dur = (v_srate * 0.1)
  v_spawn_timer = 0.0
  v_delay_len = 32.0
  v_delay_buf_l = ((v_lut_cos + v_lut_size) + 100.0)
  v_delay_buf_r = (v_delay_buf_l + v_delay_len)
  v_delay_idx = 0.0
  v_wg_mem = ((v_delay_buf_r + v_delay_len) + 100.0)
  v_wg_stride = 5.0
  v_max_wgrains = 16.0
  v_acc_len = v_single_buf_len
  v_acc_size = (v_acc_len * 3.0)
  v_ih_size = 32768.0
  v_ih_mask = 32767.0
  v_ih_l = ((v_wg_mem + (v_max_wgrains * v_wg_stride)) + 100.0)
  v_ih_r = (v_ih_l + v_ih_size)
  _t3477 = v_ih_l
  _t3478 = (v_ih_size * 2.0)
  _t3479 = _memset(_t3477, 0.0, _t3478)
  v_ih_n = 0.0
  v_wg_prev_ok = 0.0
  v_wg_prev_src = 0.0
  v_wg_prev_n = 0.0
  v_wg_lcur = 0.0
  v_rd_tmp = ((v_ih_r + v_ih_size) + 10.0)
  v_rd_prev_ok = 0.0
  v_rd_prev_start = 0.0
  v_rd_prev_n = 0.0
  v_rd_prev_dur = 0.0
  v_acc_set0 = ((v_ih_r + v_ih_size) + 400.0)
  v_acc_set1 = (v_acc_set0 + v_acc_size)
  v_acc_end = (v_acc_set1 + v_acc_size)
  v_acc_ok = (1.0 if (v_acc_end + 100.0) < v_mem_budget else 0.0)
  if _tr(v_acc_ok):
    _t3481 = v_acc_set0
    _t3482 = (v_acc_size * 2.0)
    _t3483 = _memset(_t3481, 0.0, _t3482)
    _t3480 = _t3483
  else:
    _t3480 = 0.0
  v_acc_cur = 0.0
  v_acc_cur_dirty = 0.0
  v_acc_lo = 1000000000.0
  v_acc_hi = (-1.0)
  v_acc_wmin = 0.5
  v_acc_wrep = 0.9
  v_acc_mode = 1.0
  v_cm_mode = 1.0
  v_wg_rf = 1.0
  v_wg_hop = 0.5
  v_wg_fade = 0.5
  v_wg_timer = 0.0
  v_wg_es = 0.0
  v_wg_el = 16.0
  v_wg_gl = 1.0
  v_wg_gr = 1.0
  v_cm_active = 0.0
  v_cm_k = 0.0
  v_cm_dir = 1.0
  v_cm_lo = 0.0
  v_cm_hi = 0.0
  v_cm_sb = 0.0
  v_dub_gran = 0.0
  v_dub_gran_prev = 0.0
  v_gran_now = 0.0
  v_auto_above_prev = 0.0
  v_dens_bag = (v_acc_end + 200.0)
  v_dens_bag_i = 16.0
  v_dens_carry = 0.0
  v_dens_last_occ = (-1.0)
  v_dens_g = 1.0
  v_dens_tgt = 1.0
  v_dens_slot = (-1.0)
  v_dens_rt = 0.0
  v_dens_prev_state = (-1.0)
  v_dens_force = 0.0
  v_dens_len_f = v_dens_len
  v_dens_slew = _div(1.0, (v_srate * 0.005))
  v_sl_lo = 0.0
  v_sl_hi = 0.0
  v_sl_run = 1.0
  v_sl_gate = 1.0
  v_sl_slew = _div(1.0, (v_srate * 0.003))
  v_slice_mute_gate = 1.0
  v_slice_mute_step = 0.0
  v_slice_mute_target = 1.0
  v_current_slice_pitch = 0.0
  v_cloud_lfo_phase = 0.0
  v_cloud_center_draw = 0.0
  v_wow_phase = 0.0
  v_flutter_phase = 0.0
  v_smp_nv = 16.0
  v_smp_vs = 16.0
  v_smp_voice = ((v_dens_bag + 16.0) + 100.0)
  v_smp_evmax = 512.0
  v_smp_ev_off = ((v_smp_voice + (v_smp_nv * v_smp_vs)) + 100.0)
  v_smp_ev_note = (v_smp_ev_off + v_smp_evmax)
  v_smp_ev_vel = (v_smp_ev_note + v_smp_evmax)
  _t3484 = v_smp_voice
  _t3485 = (v_smp_nv * v_smp_vs)
  _t3486 = _memset(_t3484, 0.0, _t3485)
  _t3487 = v_smp_ev_off
  _t3488 = (v_smp_evmax * 3.0)
  _t3489 = _memset(_t3487, 0.0, _t3488)
  v_trans_str = ((v_smp_ev_vel + v_smp_evmax) + 100.0)
  v_pslot = (4.0 + (v_max_transients * 2.0))
  v_preset_mem = ((v_trans_str + v_max_transients) + 100.0)
  _t3490 = v_trans_str
  _t3491 = v_max_transients
  _t3492 = _memset(_t3490, 0.0, _t3491)
  _t3493 = v_preset_mem
  _t3494 = (v_pslot * 4.0)
  _t3495 = _memset(_t3493, 0.0, _t3494)
  _t3496 = (v_srate * 0.003)
  _t3497 = _floor(_t3496)
  _t3498 = _t3497
  _t3499 = max(32.0, _t3498)
  v_odf_hop = _t3499
  _t3500 = _div(v_single_buf_len, v_odf_hop)
  _t3501 = _floor(_t3500)
  v_odf_max_n = (_t3501 + 8.0)
  v_odf_mem = ((v_preset_mem + (v_pslot * 4.0)) + 100.0)
  v_odf_cs = ((v_odf_mem + v_odf_max_n) + 16.0)
  v_odf_floor = 1e-06
  v_odf_n = 0.0
  v_odf_cnt = 0.0
  _t3502 = _div((v_srate * 0.1), v_odf_hop)
  _t3503 = _floor(_t3502)
  _t3504 = _t3503
  _t3505 = max(4.0, _t3504)
  v_odf_w = _t3505
  _t3506 = _div((((-2.0) * 3.141592653589793) * 150.0), v_srate)
  _t3507 = _exp(_t3506)
  v_odf_a_lo = (1.0 - _t3507)
  _t3508 = _div((((-2.0) * 3.141592653589793) * 2500.0), v_srate)
  _t3509 = _exp(_t3508)
  v_odf_a_mid = (1.0 - _t3509)
  _t3510 = _div((-1.0), (v_srate * 0.012))
  _t3511 = _exp(_t3510)
  v_odf_c_lo = (1.0 - _t3511)
  _t3512 = _div((-1.0), (v_srate * 0.004))
  _t3513 = _exp(_t3512)
  v_odf_c_mid = (1.0 - _t3513)
  _t3514 = _div((-1.0), (v_srate * 0.0015))
  _t3515 = _exp(_t3514)
  v_odf_c_hi = (1.0 - _t3515)
  if _tr((1.0 if v_srate > 60000.0 else 0.0)):
    _t3516 = 2048.0
  else:
    _t3516 = 1024.0
  v_st_n = _t3516
  v_st_nb = 24.0
  v_st_lag = 3.0
  v_st_rp = 0.0
  v_odf2_mem = ((v_odf_cs + v_odf_max_n) + 16.0)
  v_cand_max = 4096.0
  v_cand_k = ((v_odf2_mem + v_odf_max_n) + 16.0)
  v_cand_v = ((v_cand_k + v_cand_max) + 16.0)
  v_cand_s = ((v_cand_v + v_cand_max) + 16.0)
  v_cand_ok = ((v_cand_s + v_cand_max) + 16.0)
  v_cand_p = ((v_cand_ok + v_cand_max) + 16.0)
  v_sel_k = ((v_cand_p + v_cand_max) + 16.0)
  v_sel_s = ((v_sel_k + v_max_transients) + 16.0)
  v_st_win = ((v_sel_s + v_max_transients) + 16.0)
  v_st_band = ((v_st_win + v_st_n) + 16.0)
  v_st_ring = (v_st_band + 64.0)
  _t3517 = _div(((v_st_ring + ((v_st_lag + 1.0) * v_st_nb)) + 64.0), 4096.0)
  _t3518 = _ceil(_t3517)
  v_st_fft = (_t3518 * 4096.0)
  v_wp_max = 1024.0
  v_wp_mk = (v_st_fft + 8192.0)
  v_wp_sr = ((v_wp_mk + v_wp_max) + 16.0)
  v_wp_tg = ((v_wp_sr + v_wp_max) + 16.0)
  v_wp_dd = ((v_wp_tg + v_wp_max) + 16.0)
  v_cl_lk = ((v_wp_dd + v_wp_max) + 16.0)
  _t3519 = v_cl_lk
  _t3520 = _memset(_t3519, 0.0, 512.0)
  _t3521 = (v_srate * 0.002)
  _t3522 = _floor(_t3521)
  _t3523 = _t3522
  _t3524 = min(250.0, _t3523)
  _t3525 = _t3524
  _t3526 = max(8.0, _t3525)
  v_cl_ld = _t3526
  v_cl_li = 0.0
  v_cl_lg = 1.0
  v_cl_lh = 1.0
  v_cl_lc = 0.0
  v_cl_lth = 0.8
  _t3527 = _div((-4.0), v_cl_ld)
  _t3528 = _exp(_t3527)
  v_cl_latt = (1.0 - _t3528)
  _t3529 = _div((-1.0), (v_srate * 0.08))
  _t3530 = _exp(_t3529)
  v_cl_lrel = (1.0 - _t3530)
  v_wp_busy = 0.0
  v_wp_phase = 0.0
  v_wp_live = 0.0
  v_wp_scan = 0.0
  v_wp_prev_on = 0.0
  v_wp_mn = 0.0
  v_wp_n = 0.0
  v_wp_orig = 0.0
  v_wp_wsl = 0.0
  v_wp_tgt = 0.0
  v_wp_from = 0.0
  v_wp_sig = (-1.0)
  v_wp_sig_seen = (-1.0)
  v_wp_sig_t = 0.0
  v_wp_len = 0.0
  v_an_after_wp = 0.0
  v_wp_ls = 0.0
  v_wp_lw = 1.0
  v_i = 0.0
  for _t3531 in range(max(0, int(v_st_n))):
    _t3532 = _ix(v_st_win + v_i)
    _t3533 = _div(((2.0 * 3.141592653589793) * v_i), v_st_n)
    _t3534 = math.cos(_t3533)
    _t3535 = (0.5 - (0.5 * _t3534))
    _mset(_t3532, _t3535)
    v_i = (v_i + 1.0)
  _t3536 = (0.45 * v_srate)
  _t3537 = min(16000.0, _t3536)
  v_st_fmax = _t3537
  v_i = 0.0
  for _t3538 in range(max(0, int((v_st_nb + 1.0)))):
    _t3539 = _ix(v_st_band + v_i)
    _t3540 = _div(v_st_fmax, 80.0)
    _t3541 = _log(_t3540)
    _t3542 = _div((_t3541 * v_i), v_st_nb)
    _t3543 = _exp(_t3542)
    _t3544 = _div((80.0 * _t3543), _div(v_srate, v_st_n))
    _t3545 = _floor(_t3544)
    _t3546 = _t3545
    _mset(_t3539, _t3546)
    _t3547 = 1.0 if _tr((1.0 if v_i > 0.0 else 0.0)) else 0.0
    if _t3547:
      _t3547 = 1.0 if _tr((1.0 if _mget(v_st_band + v_i) <= _mget(v_st_band + (v_i - 1.0)) else 0.0)) else 0.0
    if _tr(_t3547):
      _t3549 = _ix(v_st_band + v_i)
      _t3550 = (_mget(v_st_band + (v_i - 1.0)) + 1.0)
      _mset(_t3549, _t3550)
      _t3548 = _t3550
    else:
      _t3548 = 0.0
    v_i = (v_i + 1.0)
  v_i = 0.0
  for _t3551 in range(max(0, int(((v_st_lag + 1.0) * v_st_nb)))):
    _t3552 = _ix(v_st_ring + v_i)
    _t3553 = 0.0
    _mset(_t3552, _t3553)
    v_i = (v_i + 1.0)
  v_lp_mute = 0.0
  v_mute_g = 1.0
  v_co_rec = 0.0
  v_co_p = 0.0
  v_slw_last = (-1.0)
  v_sl_rec = 0.0
  v_sw_on = 0.0
  v_sw_pos = 0.0
  v_dr_base = 300.0
  v_dr_mode = 0.0
  v_dr_tok = 0.0
  v_dr_j = 0.0
  v_dr_t0 = 0.0
  v_dr_t1 = 0.0
  v_dr_cnt = 0.0
  v_dr_blk = 0.0
  v_dr_l = 0.0
  v_rx_seen = _gget(398.0)
  v_det_cap = 32.0
  v_ld_base = 1000000.0
  v_ld_maxn = 3500000.0
  v_ld_active = 0.0
  v_ld_i = 0.0
  v_ld_n = 0.0
  v_ld_ref = 0.0
  v_ld_qid = 0.0
  v_ld_part = 1.0
  v_rec_force_free = 0.0
  v_x_free = 0.0
  v_xarm = 0.0
  v_x_part = 1.0
  v_x_ph_prev = (-1.0)
  v_x_event = 0.0
  v_x_mode = 0.0
  v_x_ms = 0.0
  v_x_per = 0.0
  v_an_keep = 0.0
  v_ana_mode = 0.0
  v_sel_n = 0.0
  v_cand_n = 0.0
  v_an_n = 0.0
  v_an_nr = 0.0
  v_an_ne = 0.0
  v_an_done = 0.0
  v_an_dmin = 1.0
  v_an_ns = 0.0
  _t3554 = _div((0.06 * v_srate), v_odf_hop)
  _t3555 = _ceil(_t3554)
  _t3556 = _t3555
  _t3557 = max(1.0, _t3556)
  v_an_gap = _t3557
  _t3558 = _div((-1.0), (v_srate * 0.005))
  _t3559 = _exp(_t3558)
  v_dv_rf = _t3559
  _t3560 = _div((-1.0), (v_srate * 0.12))
  _t3561 = _exp(_t3560)
  v_dv_cs = (1.0 - _t3561)
  _t3562 = (v_srate * 0.005)
  _t3563 = _floor(_t3562)
  _t3564 = _t3563
  _t3565 = max(1.0, _t3564)
  v_dv_trkn = _t3565
  v_dv_f = 0.0
  v_dv_s = 0.0
  v_dv_hold = 0.0
  v_dv_trk = 0.0
  v_dv_a = 0.0
  v_det_chg = 0.0
  v_det_rel = 0.04
  v_dv_j = 0.0
  v_dv_m = 0.0
  v_dv_lim = 0.0
  _t3566 = _div((-1.0), (v_srate * 0.03))
  _t3567 = _exp(_t3566)
  v_dt_rl = _t3567
  _t3568 = _div((-1.0), (v_srate * 0.015))
  _t3569 = _exp(_t3568)
  v_dt_rm = _t3569
  _t3570 = _div((-1.0), (v_srate * 0.008))
  _t3571 = _exp(_t3570)
  v_dt_rh = _t3571
  _t3572 = _div((-v_odf_hop), (v_srate * 0.25))
  _t3573 = _exp(_t3572)
  v_dt_kb = (1.0 - _t3573)
  _t3574 = _div((-v_odf_hop), (v_srate * 0.06))
  _t3575 = _exp(_t3574)
  v_dt_kd = (1.0 - _t3575)
  v_dt_rg = v_odf_mem
  v_dt_ri = 0.0
  v_dt_th = 6.0
  _t3576 = (v_srate * 0.06)
  _t3577 = _floor(_t3576)
  v_dt_mask = _t3577
  v_dt_cap = 30.0
  v_dt_b1 = 0.0
  v_dt_b2 = 0.0
  v_dt_el = 0.0
  v_dt_em = 0.0
  v_dt_eh = 0.0
  v_dt_gl = (-1.0)
  v_dt_gm = 0.0
  v_dt_gh = 0.0
  v_dt_hc = 0.0
  v_dt_tr = 0.0
  v_dt_bs = 0.0
  v_dt_on = 0.0
  v_dt_pk = 0.0
  v_an_gapm = 1.0
  v_an_exit_pending = 0.0
  v_an_wrap_pending = 0.0
  v_an_prev_state = (-1.0)
  v_an_prev_hist = 0.0
  v_preset_cur = (-1.0)
  v_last_preset = (-1.0)
  v_last_steps = v_slicer_steps
  v_last_max_sl = v_max_slices
  v_steps_f = v_slicer_steps
  v_maxsl_f = v_max_slices
  v_smp_att = _div(1.0, (v_srate * 0.002))
  _t3578 = (v_srate * 0.003)
  _t3579 = max(1.0, _t3578)
  v_smp_tail = _t3579
  v_smp_choke_rel = _div(1.0, (v_srate * 0.004))
  v_smp_quick_rel = _div(1.0, (v_srate * 0.005))
  v_smp_l = 0.0
  v_smp_r = 0.0
  v_smp_rl = 0.0
  v_smp_rr = 0.0
  v_smp_age = 0.0
  v_smp_armed = 0.0
  v_smp_kmode = 0.0
  v_smp_mode = 0.0
  v_smp_prev_mode = 0.0
  v_smp_g = 4096.0
  v_smp_gh = 2048.0
  v_smp_ev_n = 0.0
  v_smp_ev_i = 0.0
  v_smp_blk = 0.0
  v_smp_alloff = 0.0
  v_smp_nact = 0.0
  v_sampler_root_f = v_sampler_root
  _t3580 = _div(v_sampler_release, 3000.0)
  _t3581 = _sqrt(_t3580)
  v_sampler_rel_u = _t3581
  v_gm_pspread_slicer = 34.0
  v_gm_pspread_cloud = 35.0
  v_gm_sampler_root = 150.0
  v_gm_sampler_armed = 151.0
  v_gm_sampler_voices = 152.0
  v_gm_sampler_release = 154.0
  v_gm_sampler_pmode = 153.0
  v_gm_bpm = 155.0
  v_write_ptr = 0.0
  v_state = 0.0
  v_state_target = 2.0
  v_last_state_target = 2.0
  v_rec_cmd = 0.0
  v_pending_next_state = 2.0
  v_target_sync_len = 0.0
  v_pos = 0.0
  v_old_pos_ptr = 0.0
  v_length = 0.0
  v_loop_start = 0.0
  v_loop_width = 0.0
  v_base_loop_length = 0.0
  v_mult_len = 0.0
  v_master_pos = 0.0
  v_clk_cyc = 0.0
  v_master_pos1 = 0.0
  v_master_pos2 = 0.0
  v_master_pos3 = 0.0
  v_is_normal_playback = 0.0
  v_prev_normal_playback = 0.0
  v_can_sync = 0.0
  v_last_ghost_pct = 0.0
  v_prev_rev_on = 0.0
  v_clk_cyc = 0.0
  v_clk_cyc1 = 0.0
  v_clk_cyc2 = 0.0
  v_clk_cyc3 = 0.0
  v_clk_len_ref = 0.0
  v_sync_a = 0.0
  v_sync_b = 0.0
  v_sync_c_w = 0.0
  v_sync_c_l = 0.0
  v_sync_c_r = 0.0
  v_prev_sync_key = 0.0
  v_prev_cloud_on = 0.0
  v_prev_xcl = 0.0
  v_ml_ok = 0.0
  v_ml_fwd_free = 0.0
  v_ml_cool = 0.0
  v_active_control = 0.0
  v_smooth_start = 0.0
  v_smooth_width = 0.0
  v_param_smooth_coeff = 0.95
  v_xfade_pos_active = 0.0
  v_xfade_pos_len = (v_srate * 0.015)
  v_xfade_pos_count = 0.0
  v_xf_on = 0.0
  v_xf_k = 0.0
  v_xf_inc = 0.0
  v_xf_eqp = 0.0
  v_xf_l = 0.0
  v_xf_r = 0.0
  v_xf_p = 0.0
  v_xf_st = 0.0
  v_xf_ws = 0.0
  v_xf_we = 1.0
  v_xf_g = 0.0
  v_xf_pan = 0.0
  v_xf_pamt = 0.0
  v_rd_valid = 0.0
  v_rd_last_l = 0.0
  v_rd_last_r = 0.0
  v_rd_last_p = 0.0
  v_rd_last_st = 0.0
  v_rd_last_ws = 0.0
  v_rd_last_we = 1.0
  v_rd_last_g = 0.0
  v_rd_last_pan = 0.0
  v_rd_last_pamt = 0.0
  _t3582 = (v_srate * 0.0025)
  _t3583 = _floor(_t3582)
  _t3584 = _t3583
  _t3585 = max(16.0, _t3584)
  v_xf_len_slice = _t3585
  _t3586 = (v_srate * 0.012)
  _t3587 = _floor(_t3586)
  _t3588 = _t3587
  _t3589 = max(16.0, _t3588)
  v_xf_len_jump = _t3589
  _t3590 = (v_srate * 0.006)
  _t3591 = _floor(_t3590)
  _t3592 = _t3591
  _t3593 = max(16.0, _t3592)
  v_xf_len_rs = _t3593
  _t3594 = (v_srate * 0.002)
  _t3595 = _floor(_t3594)
  v_sl_pre_t = _t3595
  v_pd_l = 0.0
  v_pd_r = 0.0
  v_pd_arm = 0.0
  v_pd_prev_l = 0.0
  v_pd_prev_r = 0.0
  _t3596 = _div((-1.0), (v_srate * 0.0025))
  _t3597 = _exp(_t3596)
  v_pd_k = _t3597
  v_sl_pan_amt = 0.0
  _t3598 = _div((-1.0), (v_srate * 0.004))
  _t3599 = _exp(_t3598)
  v_sl_pan_k = (1.0 - _t3599)
  v_slice_hold = 0.0
  v_dens_seg = 0.0
  v_dens_t = 0.0
  v_dens_ton = 0.0
  v_dens_next_on = 1.0
  v_dens_first = 1.0
  _t3600 = (v_srate * 0.03)
  _t3601 = _floor(_t3600)
  _t3602 = _t3601
  _t3603 = max(16.0, _t3602)
  v_dens_minlen = _t3603
  v_ar_in = 0.0
  v_ar_lp = 0.0
  v_ar_cnt = 0.0
  v_rp_tail_on = 0.0
  _t3604 = _div((-1.0), (v_srate * 0.0005))
  _t3605 = _exp(_t3604)
  v_ar_att = (1.0 - _t3605)
  _t3606 = _div((-1.0), (v_srate * 0.04))
  _t3607 = _exp(_t3606)
  v_ar_rel = (1.0 - _t3607)
  _t3608 = (v_srate * 0.03)
  _t3609 = _floor(_t3608)
  v_ar_hold = _t3609
  v_ar_up = _div(1.0, (v_srate * 0.003))
  v_ar_dn = _div(1.0, (v_srate * 0.025))
  v_cl_mem = 11700000.0
  v_cl_max = 32.0
  v_cl_stride = 16.0
  _t3610 = v_cl_mem
  _t3611 = (v_cl_max * v_cl_stride)
  _t3612 = _memset(_t3610, 0.0, _t3611)
  v_cl_timer = 0.0
  v_cl_n = 2.0
  v_cl_a = 0.0
  v_cl_center = 0.0
  v_cl_g = 1.0
  v_cl_out_l = 0.0
  v_cl_out_r = 0.0
  v_cl_act = 0.0
  v_frz_l = 11800000.0
  v_frz_max = 1000000.0
  v_frz_r = (v_frz_l + v_frz_max)
  v_frz_len = 0.0
  v_frz_i = 0.0
  v_frz_copying = 0.0
  v_frz_ready = 0.0
  v_frz_prev = (-1.0)
  v_frz_center = 0.0
  v_df_sc = _div(v_srate, 48000.0)
  v_df_mem = ((v_cl_mem + (v_cl_max * v_cl_stride)) + 100.0)
  v_df_p = v_df_mem
  _t3613 = f_df_alloc(229.0)
  v_df_a1 = _t3613
  _t3614 = f_df_alloc(317.0)
  v_df_a2 = _t3614
  _t3615 = f_df_alloc(491.0)
  v_df_a3 = _t3615
  _t3616 = f_df_alloc(677.0)
  v_df_a4 = _t3616
  _t3617 = f_df_alloc(2789.0)
  v_df_dl = _t3617
  _t3618 = f_df_alloc(241.0)
  v_df_b1 = _t3618
  _t3619 = f_df_alloc(331.0)
  v_df_b2 = _t3619
  _t3620 = f_df_alloc(503.0)
  v_df_b3 = _t3620
  _t3621 = f_df_alloc(701.0)
  v_df_b4 = _t3621
  _t3622 = f_df_alloc(3011.0)
  v_df_dr = _t3622
  v_df_fl = 0.0
  v_df_fr = 0.0
  v_df_lp_l = 0.0
  v_df_lp_r = 0.0
  v_df_on = 0.0
  v_slice_env = 1.0
  v_slice_decay_samples = (v_srate * 0.15)
  v_slice_decay_step = _div(1.0, v_slice_decay_samples)
  v_slice_att = 1.0
  v_slice_att_step = 0.0
  v_slice_att_eff_ms = 0.0
  v_replace_fade = 0.0
  v_replace_fade_coeff = _div(1.0, (v_srate * 0.02))
  v_state_transition_fade = 1.0
  v_dub_pf = 0.0
  v_dub_g = 1.0
  _t3623 = (v_srate * 0.005)
  _t3624 = max(1.0, _t3623)
  v_dub_pfk = _div(1.0, _t3624)
  v_rec_lag_pend = 0.0
  v_rec_start_lag = 0.0
  v_rec_stop_lag = 0.0
  v_lat_samps = 0.0
  v_wr_off = 0.0
  v_prev_in0 = 0.0
  v_prev_in1 = 0.0
  v_grain_mix = 0.0
  v_xfade_coeff = _div(1.0, (v_srate * 0.01))
  v_init_done = 0.0
  v_tape_lpf_l = 0.0
  v_tape_lpf_r = 0.0
  v_tape_lpf_l_b = 0.0
  v_tape_lpf_r_b = 0.0
  v_tape_lpf_l_c = 0.0
  v_tape_lpf_r_c = 0.0
  v_tape_lpf_l_d = 0.0
  v_tape_lpf_r_d = 0.0
  v_slice_pan = 0.0
  v_dub_pan = 0.0
  v_last_slider9 = v_loop_pos_pct
  v_last_sens = v_trans_sens
  v_last_hold = v_trans_hold_ms
  v_last_det_t = v_det_thresh
  v_last_det_h = v_det_hold_ms
  v_last_slicer_mode = v_slicer_mode
  v_last_grid_sub = v_grid_sub
  v_last_pitch_spread = v_slicer_pitch_spread
  v_last_slicer_src = (-1.0)
  v_slicer_sample_counter = 0.0
  v_slicer_current_step = 0.0
  v_auto_rep_hold_counter = 0.0
  v_auto_rep_active = 0.0
  v_input_env = 0.0
  v_ping_pong_dir = 1.0
  v_last_slicer_step = (-1.0)
  v_one_shot_playing = 0.0
  v_one_shot_pp_state = 0.0
  v_analysing = 0.0
  v_ana_k = 0.0
  v_ana_end = 0.0
  v_ana_max_peak = 0.0001
  v_ana_min_dist = 0.0
  v_ana_win_size = 0.0
  v_ana_env = 0.0
  v_ana_last_trig = 0.0
  v_ui_en = 1.0
  v_ui_chg = 0.0
  v_ui_hov = 0.0
  v_ui_ar = 1.0
  v_ui_ag = 1.0
  v_ui_ab = 1.0
  v_last_mouse_cap = 0.0
  v_last_mouse_y = 0.0
  v_auto_on = 0.0
  v_clr_press_time = 0.0
  v_clr_long_pressed = 0.0
  v_input_signal_active = 0.0
  v_hold_samples_left = 0.0
  v_cloud_on = 0.0
  v_cloud_density = 0.5
  v_cloud_chaos = 0.0
  v_cloud_spread = 0.1
  v_cloud_pitch_spread = 0.0
  v_cloud_mix = 1.0
  v_cloud_pos_mode = 1.0
  v_cloud_pos_pct = 50.0
  v_cloud_lfo_shape = 0.0
  v_cloud_lfo_rate = 1.0
  v_cloud_lfo_depth = 0.0
  v_loop_quant = 0.0
  v_grid_pending = 0.0
  v_grid_sig = (-1.0)
  v_last_link = v_slicer_link
  v_an_win_last = (-1.0)
  v_an_win_pend = 0.0
  v_an_win_t = 0.0
  v_peak_in_vu = 0.0
  v_peak_loop_vu = 0.0
  v_peak_out_vu = 0.0
  _t3625 = _div((-1.0), (v_srate * 0.4))
  _t3626 = _exp(_t3625)
  v_vu_rel = _t3626
  v_prev_sm_speed = (-1.0)
  v_prev_loop_start = (-1.0)
  v_prev_loop_width = (-1.0)
  v_prev_pitch_ratio_sig = (-1.0)
  v_prev_pingpong_on = 0.0
  v_prev_play_mode = (-1.0)
  v_prev_state_for_sync = (-1.0)
  v_sync_hard_resync = 0.0
  v_loop_edit_mode = 0.0
  v_io_w_lock = 0.0
  v_io_e_lock = 0.0
  v_br_on = 0.0
  v_br_saved_start = 0.0
  v_br_saved_width = 0.0
  v_br_mix_s = v_br_mix
  v_slx_mix_s = v_slx_mix
  v_slx_pos = 0.0
  v_slx_prev = 0.0
  v_br_bg_pos = 0.0
  v_br_bg_s = 0.0
  v_br_bg_e = 0.0
  v_last_loop_quant = (-1.0)
  v_br_suppress_an = 0.0
  v_rec_start_time = 0.0
  return 0

def sec_slider():
  global v_br_on, v_cloud_chaos, v_cloud_density, v_cloud_lfo_depth, v_cloud_lfo_rate, v_cloud_lfo_shape, v_cloud_mix, v_cloud_on, v_cloud_pitch_spread, v_cloud_pos_mode, v_cloud_pos_pct, v_cloud_spread, v_det_chg, v_det_hold_ms, v_det_thresh, v_grid_sub, v_last_det_h, v_last_det_t, v_last_loop_quant, v_last_pitch_spread, v_last_slicer_mode, v_last_slider9, v_length, v_loop_pos_pct, v_loop_quant, v_loop_start, v_loop_width, v_looper_hue, v_pos, v_prev_loop_start, v_prev_loop_width, v_req_p, v_slice_decay_ms, v_slice_decay_pos, v_slicer_current_step, v_slicer_mode, v_slicer_pitch_spread, v_step_len, v_sync_hard_resync
  _t3629 = v_slice_decay_pos
  _t3627 = v_slice_decay_ms
  _t3628 = f_decay_ms_to_pos(_t3627)
  _t3630 = (_t3629 - _t3628)
  _t3631 = abs(_t3630)
  if _tr((1.0 if _t3631 > 0.06 else 0.0)):
    _t3633 = v_slice_decay_pos
    _t3634 = f_decay_pos_to_ms(_t3633)
    v_slice_decay_ms = _t3634
    if _tr((1.0 if v_slice_decay_ms < 1950.0 else 0.0)):
      _t3636 = (v_slice_decay_ms + 0.5)
      _t3637 = _floor(_t3636)
      _t3638 = _t3637
      _t3639 = max(4.0, _t3638)
      v_slice_decay_ms = _t3639
      _t3635 = v_slice_decay_ms
    else:
      _t3635 = 0.0
    _t3632 = _t3635
  else:
    _t3632 = 0.0
  if _tr((0.0 if abs(v_loop_pos_pct - v_last_slider9) < 0.00001 else 1.0)):
    if _tr((1.0 if v_length > 0.0 else 0.0)):
      v_req_p = ((v_loop_pos_pct * 0.01) * v_length)
      _t3642 = (v_req_p - v_pos)
      _t3643 = abs(_t3642)
      if _tr((1.0 if _t3643 > 10.0 else 0.0)):
        _t3645 = v_req_p
        _t3646 = f_trigger_pos_jump(_t3645)
        _t3644 = _t3646
      else:
        _t3644 = 0.0
      _t3641 = _t3644
    else:
      _t3641 = 0.0
    v_last_slider9 = v_loop_pos_pct
    _t3640 = v_last_slider9
  else:
    _t3640 = 0.0
  _t3647 = 1.0 if _tr((0.0 if abs(v_det_thresh - v_last_det_t) < 0.00001 else 1.0)) else 0.0
  if not _t3647:
    _t3647 = 1.0 if _tr((0.0 if abs(v_det_hold_ms - v_last_det_h) < 0.00001 else 1.0)) else 0.0
  if _tr(_t3647):
    v_last_det_t = v_det_thresh
    v_last_det_h = v_det_hold_ms
    v_det_chg = 1.0
    _t3648 = v_det_chg
  else:
    if _tr((0.0 if abs(v_slicer_mode - v_last_slicer_mode) < 0.00001 else 1.0)):
      _t3650 = f_get_slicer_len()
      v_step_len = _t3650
      _t3651 = v_step_len
      _t3652 = f_generate_slicer_sequence(_t3651)
      v_last_slicer_mode = v_slicer_mode
      v_slicer_current_step = 0.0
      _t3649 = v_slicer_current_step
    else:
      _t3649 = 0.0
    _t3648 = _t3649
  if _tr((0.0 if abs(v_slicer_pitch_spread - v_last_pitch_spread) < 0.00001 else 1.0)):
    v_last_pitch_spread = v_slicer_pitch_spread
    _t3654 = f_get_slicer_len()
    _t3655 = _t3654
    _t3656 = f_update_slicer_pitches(_t3655)
    _t3653 = _t3656
  else:
    _t3653 = 0.0
  v_cloud_on = v_cloud_on
  v_loop_quant = v_loop_quant
  _t3658 = 1.0 if _tr((1.0 if v_last_loop_quant >= 0.0 else 0.0)) else 0.0
  if _t3658:
    _t3658 = 1.0 if _tr((0.0 if abs(v_loop_quant - v_last_loop_quant) < 0.00001 else 1.0)) else 0.0
  _t3657 = 1.0 if _tr(_t3658) else 0.0
  if _t3657:
    _t3657 = 1.0 if _tr(v_br_on) else 0.0
  if _tr(_t3657):
    _t3660 = f_br_refresh()
    _t3659 = _t3660
  else:
    _t3659 = 0.0
  v_last_loop_quant = v_loop_quant
  v_cloud_density = v_cloud_density
  v_cloud_chaos = v_cloud_chaos
  v_cloud_spread = v_cloud_spread
  v_cloud_pitch_spread = v_cloud_pitch_spread
  v_cloud_mix = v_cloud_mix
  v_cloud_pos_mode = v_cloud_pos_mode
  v_cloud_pos_pct = v_cloud_pos_pct
  v_cloud_lfo_shape = v_cloud_lfo_shape
  v_cloud_lfo_rate = v_cloud_lfo_rate
  v_cloud_lfo_depth = v_cloud_lfo_depth
  v_grid_sub = v_grid_sub
  v_looper_hue = v_looper_hue
  _t3661 = 1.0 if _tr((0.0 if abs(v_loop_start - v_prev_loop_start) < 0.00001 else 1.0)) else 0.0
  if not _t3661:
    _t3661 = 1.0 if _tr((0.0 if abs(v_loop_width - v_prev_loop_width) < 0.00001 else 1.0)) else 0.0
  if _tr(_t3661):
    v_sync_hard_resync = 1.0
    _t3662 = v_sync_hard_resync
  else:
    _t3662 = 0.0
  return 0

def sec_block():
  global v_active_control, v_active_history_idx, v_active_part, v_an_bj, v_an_bs, v_an_d, v_an_dmin, v_an_done, v_an_exit_pending, v_an_gapm, v_an_j, v_an_keep, v_an_kk, v_an_n, v_an_ne, v_an_nr, v_an_ns, v_an_osub, v_an_prev_hist, v_an_prev_state, v_an_q, v_an_r, v_an_sc, v_an_target, v_an_wasg, v_an_win_last, v_an_win_pend, v_an_win_sig, v_an_win_t, v_an_wrap_pending, v_ana_budget, v_ana_end, v_ana_k, v_ana_max_peak, v_ana_mode, v_analysing, v_auto_on, v_base_len_part1, v_base_len_part2, v_base_len_part3, v_base_loop_length, v_beat_position, v_blk_ms, v_br_mix, v_br_on, v_br_suppress_an, v_cand_k, v_cand_n, v_cand_ok, v_cand_s, v_cand_v, v_clk_src, v_cloud_chaos, v_cloud_density, v_cloud_diffuse, v_cloud_freeze, v_cloud_lfo_depth, v_cloud_lfo_rate, v_cloud_lfo_shape, v_cloud_mix, v_cloud_on, v_cloud_pitch_spread, v_cloud_pos_mode, v_cloud_pos_pct, v_cloud_size, v_cloud_spread, v_cm_active, v_cmd, v_cmd_arg, v_cmd_lag, v_degradation, v_dens_len, v_dens_occ, v_det_cap, v_det_chg, v_det_hold_ms, v_det_rel, v_det_strict, v_det_thresh, v_dr_mode, v_dt_b1, v_dt_b2, v_dt_cap, v_dt_eh, v_dt_el, v_dt_em, v_dt_gl, v_dt_hc, v_dt_pk, v_dt_rh, v_dt_rl, v_dt_rm, v_dt_tr, v_dt_x, v_dt_xl, v_dt_xr, v_dub_align_ms, v_dub_grain_ms, v_dv_a, v_dv_f, v_dv_hold, v_dv_j, v_dv_lim, v_dv_m, v_dv_rf, v_edit_cmd, v_fade_ms, v_feedback, v_frz_center, v_frz_copying, v_frz_i, v_frz_l, v_frz_len, v_frz_max, v_frz_n, v_frz_prev, v_frz_r, v_frz_ready, v_ghost_pos_pct, v_gm_bpm, v_gm_pspread_cloud, v_gm_pspread_slicer, v_gm_sampler_armed, v_gm_sampler_pmode, v_gm_sampler_release, v_gm_sampler_root, v_gm_sampler_voices, v_gmem, v_gmem_base, v_gq, v_grain_fade, v_grain_ms, v_grid_pending, v_grid_sig, v_grid_sub, v_i, v_inst_idx, v_instance_alias, v_instance_id, v_is_active, v_keep_w, v_last_grid_sub, v_last_link, v_last_max_sl, v_last_pitch_spread, v_last_preset, v_last_slicer_src, v_last_slicer_step, v_last_slider9, v_last_steps, v_lat_samps, v_ld_active, v_left_buf, v_len_part1, v_len_part2, v_len_part3, v_length, v_link_on, v_loop_beats, v_loop_pos_pct, v_loop_quant, v_loop_start, v_loop_width, v_looper_hue, v_lp_mute, v_manual_id, v_master_pos, v_max_len_exp, v_max_slices, v_max_transients, v_mclk_cyc, v_mclk_d, v_mclk_len, v_mclk_len_prev, v_mclk_m, v_mclk_np, v_mclk_on, v_mclk_pos, v_mclk_trk, v_mclk_valid, v_mix, v_mo_m1, v_mo_m2, v_mo_m3, v_mo_off, v_mo_t, v_new_in, v_new_out, v_new_w, v_odf_a_lo, v_odf_a_mid, v_odf_hop, v_odf_ix, v_odf_ls, v_odf_lw, v_old_end, v_out_vol, v_p, v_p_len, v_param_clear_base, v_param_clear_i, v_param_gmem_base, v_part_sp, v_peak_in_vu, v_peak_out_vu, v_pending_part_switch, v_pingpong_on, v_pitch, v_play_mode, v_pos, v_preset_cur, v_prev_xcl, v_qs_b0, v_qs_i, v_read_align_ms, v_rec_cmd, v_rec_lag_pend, v_req_p, v_req_part, v_rev_on, v_right_buf, v_sampler_pitch_mode, v_sampler_release, v_sampler_root, v_samplesblock, v_saved_manual_id, v_sel_k, v_sel_n, v_sel_s, v_slice_attack_ms, v_slice_decay_ms, v_slice_decay_pos, v_slice_gmem_base, v_slice_gmem_i, v_slicer_current_step, v_slicer_link, v_slicer_mode, v_slicer_pitch_spread, v_slicer_preset, v_slicer_src, v_slicer_steps, v_slicer_sub, v_slx_mix, v_smp_alloff, v_smp_ev_i, v_smp_ev_n, v_smp_ev_note, v_smp_ev_off, v_smp_ev_vel, v_smp_evmax, v_smp_mode, v_smp_nact, v_speed, v_srate, v_src_auto, v_st, v_state, v_state_slider, v_state_target, v_stereo_width, v_sy_pbase, v_sy_plen, v_sync_hard_resync, v_target_part, v_trans_count, v_trans_hold_ms, v_trans_mem, v_trans_sens, v_w_idx_ex, v_w_step_ex, v_w_tmp_ex, v_w_val_ex, v_warp_force, v_warp_grid, v_warp_on, v_wave_export_slots, v_wi_ex, v_wk_ex, v_wp_max, v_wp_mk, v_wp_mn, v_wp_phase, v_wp_pub, v_wp_ri, v_wp_scan, v_wr_id, v_wr_mb, v_wr_mo, v_wr_v, v_x_free, v_x_part, v_xarm
  v_smp_ev_n = 0.0
  v_smp_ev_i = 0.0
  if _tr((1.0 if abs(_gget(957.0) - 2.0) < 0.00001 else 0.0)):
    _t3663 = 0.0
  else:
    _t3664 = (v_srate * 0.1)
    _t3665 = (_gget(955.0) + ((_gget(956.0) * v_srate) * 0.001))
    _t3666 = min(_t3664, _t3665)
    _t3667 = _t3666
    _t3668 = max(0.0, _t3667)
    _t3663 = _t3668
  v_lat_samps = _t3663
  if _tr((0.0 if abs(v_cloud_freeze - v_frz_prev) < 0.00001 else 1.0)):
    v_frz_prev = v_cloud_freeze
    if _tr((1.0 if v_cloud_freeze >= 0.5 else 0.0)):
      v_frz_center = v_pos
      _t3671 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
      if _t3671:
        _t3671 = 1.0 if _tr((1.0 if v_length <= v_frz_max else 0.0)) else 0.0
      if _tr(_t3671):
        v_frz_len = v_length
        v_frz_i = 0.0
        v_frz_copying = 1.0
        v_frz_ready = 0.0
        _t3672 = v_frz_ready
      else:
        v_frz_copying = 0.0
        v_frz_ready = 0.0
        _t3672 = v_frz_ready
      _t3670 = _t3672
    else:
      _t3670 = 0.0
    _t3669 = _t3670
  else:
    _t3669 = 0.0
  if _tr(v_frz_copying):
    _t3674 = (v_frz_len - v_frz_i)
    _t3675 = min(65536.0, _t3674)
    v_frz_n = _t3675
    _t3676 = (v_frz_l + v_frz_i)
    _t3677 = (v_left_buf + v_frz_i)
    _t3678 = v_frz_n
    _t3679 = _memcpy(_t3676, _t3677, _t3678)
    _t3680 = (v_frz_r + v_frz_i)
    _t3681 = (v_right_buf + v_frz_i)
    _t3682 = v_frz_n
    _t3683 = _memcpy(_t3680, _t3681, _t3682)
    v_frz_i = (v_frz_i + v_frz_n)
    if _tr((1.0 if v_frz_i >= v_frz_len else 0.0)):
      v_frz_copying = 0.0
      v_frz_ready = 1.0
      _t3684 = v_frz_ready
    else:
      _t3684 = 0.0
    _t3673 = _t3684
  else:
    _t3673 = 0.0
  v_qs_b0 = v_beat_position
  v_qs_i = 0.0
  _t3685 = f_rp_check()
  _t3686 = 1.0 if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)) else 0.0
  if _t3686:
    _t3686 = 1.0 if _tr(v_cloud_on) else 0.0
  if _tr(_t3686):
    if _tr((0.0 if abs(v_cloud_on - v_prev_xcl) < 0.00001 else 1.0)):
      v_play_mode = 0.0
      v_play_mode = 0.0
      _t3688 = v_play_mode
    else:
      v_cloud_on = 0.0
      v_cloud_on = 0.0
      _t3688 = v_cloud_on
    _t3687 = _t3688
  else:
    _t3687 = 0.0
  v_prev_xcl = v_cloud_on
  v_blk_ms = ((v_active_part - 1.0) * 10.0)
  _t3691 = 1.0 if _tr((1.0 if abs(_gget(v_blk_ms) - 1.0) < 0.00001 else 0.0)) else 0.0
  if _t3691:
    _t3691 = 1.0 if _tr((0.0 if abs(_gget((v_blk_ms + 1.0)) - v_instance_id) < 0.00001 else 1.0)) else 0.0
  _t3690 = 1.0 if _tr(_t3691) else 0.0
  if _t3690:
    _t3690 = 1.0 if _tr((0.0 if abs(_gget((v_blk_ms + 1.0)) - v_instance_alias) < 0.00001 else 1.0)) else 0.0
  _t3689 = 1.0 if _tr(_t3690) else 0.0
  if _t3689:
    _t3689 = 1.0 if _tr((1.0 if _gget((v_blk_ms + 2.0)) > 0.0 else 0.0)) else 0.0
  v_mclk_trk = _t3689
  _t3692 = 1.0 if _tr((1.0 if abs(v_clk_src - 0.0) < 0.00001 else 0.0)) else 0.0
  if _t3692:
    _t3692 = 1.0 if _tr(v_mclk_trk) else 0.0
  v_mclk_on = _t3692
  _t3693 = 1.0 if _tr((0.0 if abs(v_xarm - 0.0) < 0.00001 else 1.0)) else 0.0
  if _t3693:
    _t3693 = 1.0 if _tr((0.0 if abs(v_x_part - v_active_part) < 0.00001 else 1.0)) else 0.0
  if _tr(_t3693):
    v_xarm = 0.0
    _t3694 = v_xarm
  else:
    _t3694 = 0.0
  if _tr((0.0 if abs(v_xarm - 0.0) < 0.00001 else 1.0)):
    _t3696 = f_x_select_mode()
    _t3695 = _t3696
  else:
    _t3695 = 0.0
  if _tr(v_ld_active):
    _t3698 = f_ld_step()
    _t3697 = _t3698
  else:
    _t3697 = 0.0
  if _tr(v_dr_mode):
    _t3700 = f_dr_step()
    _t3699 = _t3700
  else:
    _t3699 = 0.0
  _t3701 = f_rx_poll()
  if _tr(v_mclk_trk):
    v_mclk_len = _gget((v_blk_ms + 2.0))
    v_mclk_m = _gget((v_blk_ms + 3.0))
    _t3703 = 1.0 if _tr((0.0 if _tr(v_mclk_valid) else 1.0)) else 0.0
    if not _t3703:
      _t3703 = 1.0 if _tr((0.0 if abs(v_mclk_len - v_mclk_len_prev) < 0.00001 else 1.0)) else 0.0
    if _tr(_t3703):
      v_mclk_pos = v_mclk_m
      v_mclk_cyc = _mod(_gget((v_blk_ms + 4.0)), 840.0)
      v_mclk_valid = 1.0
      v_mclk_len_prev = v_mclk_len
      if _tr(v_mclk_on):
        v_last_slicer_step = (-1.0)
        _t3705 = v_last_slicer_step
      else:
        _t3705 = 0.0
      _t3704 = _t3705
    else:
      v_mclk_d = (v_mclk_m - v_mclk_pos)
      _t3708 = v_mclk_len
      _t3706 = (_div(v_mclk_d, v_mclk_len) + 0.5)
      _t3707 = _floor(_t3706)
      v_mclk_d = (v_mclk_d - (_t3708 * _t3707))
      _t3712 = v_mclk_pos
      _t3709 = v_mclk_d
      _t3710 = abs(_t3709)
      if _tr((1.0 if _t3710 > 4096.0 else 0.0)):
        _t3711 = v_mclk_d
      else:
        _t3711 = (v_mclk_d * 0.1)
      v_mclk_np = (_t3712 + _t3711)
      if _tr((1.0 if v_mclk_np >= v_mclk_len else 0.0)):
        v_mclk_np = (v_mclk_np - v_mclk_len)
        v_mclk_cyc = _mod((v_mclk_cyc + 1.0), 840.0)
        _t3713 = v_mclk_cyc
      else:
        if _tr((1.0 if v_mclk_np < 0.0 else 0.0)):
          v_mclk_np = (v_mclk_np + v_mclk_len)
          v_mclk_cyc = _mod((v_mclk_cyc + 839.0), 840.0)
          _t3714 = v_mclk_cyc
        else:
          _t3714 = 0.0
        _t3713 = _t3714
      v_mclk_pos = v_mclk_np
      _t3704 = v_mclk_pos
    _t3702 = _t3704
  else:
    v_mclk_valid = 0.0
    _t3702 = v_mclk_valid
  _t3715 = 0
  while True:
    _t3716 = v_mo_off
    _t3717 = v_mo_m1
    _t3718 = v_mo_m2
    _t3719 = v_mo_m3
    _t3720 = _zero(_t3716, _t3717, _t3718, _t3719)
    if not _tr(_t3720): break
    _t3721 = v_mo_off
    _t3722 = v_mo_m1
    _t3723 = v_mo_m2
    _t3724 = v_mo_m3
    _t3725 = _zero(_t3721, _t3722, _t3723, _t3724)
    v_mo_t = float(int(v_mo_m1) & int(240.0))
    _t3726 = 1.0 if _tr((1.0 if abs(v_mo_t - 144.0) < 0.00001 else 0.0)) else 0.0
    if _t3726:
      _t3726 = 1.0 if _tr((1.0 if v_mo_m3 > 0.0 else 0.0)) else 0.0
    if _tr(_t3726):
      if _tr((1.0 if v_smp_ev_n < v_smp_evmax else 0.0)):
        _t3729 = _ix(v_smp_ev_off + v_smp_ev_n)
        _t3730 = v_mo_off
        _mset(_t3729, _t3730)
        _t3731 = _ix(v_smp_ev_note + v_smp_ev_n)
        _t3732 = v_mo_m2
        _mset(_t3731, _t3732)
        _t3733 = _ix(v_smp_ev_vel + v_smp_ev_n)
        _t3734 = v_mo_m3
        _mset(_t3733, _t3734)
        v_smp_ev_n = (v_smp_ev_n + 1.0)
        _t3728 = v_smp_ev_n
      else:
        _t3728 = 0.0
      _t3727 = _t3728
    else:
      _t3735 = 1.0 if _tr((1.0 if abs(v_mo_t - 128.0) < 0.00001 else 0.0)) else 0.0
      if not _t3735:
        _t3735 = 1.0 if _tr((1.0 if abs(v_mo_t - 144.0) < 0.00001 else 0.0)) else 0.0
      if _tr(_t3735):
        if _tr((1.0 if v_smp_ev_n < v_smp_evmax else 0.0)):
          _t3738 = _ix(v_smp_ev_off + v_smp_ev_n)
          _t3739 = v_mo_off
          _mset(_t3738, _t3739)
          _t3740 = _ix(v_smp_ev_note + v_smp_ev_n)
          _t3741 = v_mo_m2
          _mset(_t3740, _t3741)
          _t3742 = _ix(v_smp_ev_vel + v_smp_ev_n)
          _t3743 = 0.0
          _mset(_t3742, _t3743)
          v_smp_ev_n = (v_smp_ev_n + 1.0)
          _t3737 = v_smp_ev_n
        else:
          _t3737 = 0.0
        _t3736 = _t3737
      else:
        _t3744 = 1.0 if _tr((1.0 if abs(v_mo_t - 176.0) < 0.00001 else 0.0)) else 0.0
        if _t3744:
          _t3745 = 1.0 if _tr((1.0 if abs(v_mo_m2 - 123.0) < 0.00001 else 0.0)) else 0.0
          if not _t3745:
            _t3745 = 1.0 if _tr((1.0 if abs(v_mo_m2 - 120.0) < 0.00001 else 0.0)) else 0.0
          _t3744 = 1.0 if _tr(_t3745) else 0.0
        if _tr(_t3744):
          v_smp_alloff = 1.0
          _t3746 = v_smp_alloff
        else:
          _t3746 = 0.0
        _t3736 = _t3746
      _t3727 = _t3736
    _t3715 += 1
    if _t3715 > 1000000: break
  _t3747 = 1.0 if _tr((0.0 if abs(v_slicer_src - v_last_slicer_src) < 0.00001 else 1.0)) else 0.0
  if not _t3747:
    _t3747 = 1.0 if _tr((0.0 if abs(v_grid_sub - v_last_grid_sub) < 0.00001 else 1.0)) else 0.0
  if _tr(_t3747):
    v_last_slicer_src = v_slicer_src
    v_last_grid_sub = v_grid_sub
    v_grid_sig = (-1.0)
    if _tr((1.0 if v_length > 0.0 else 0.0)):
      _t3750 = f_start_analysis_ex(1.0)
      _t3749 = _t3750
    else:
      _t3749 = 0.0
    _t3748 = _t3749
  else:
    _t3748 = 0.0
  if _tr((0.0 if abs(v_slicer_pitch_spread - v_last_pitch_spread) < 0.00001 else 1.0)):
    v_last_pitch_spread = v_slicer_pitch_spread
    _t3752 = f_get_slicer_len()
    _t3753 = _t3752
    _t3754 = f_update_slicer_pitches(_t3753)
    _t3751 = _t3754
  else:
    _t3751 = 0.0
  _t3757 = 1.0 if _tr((1.0 if abs(v_slicer_src - 1.0) < 0.00001 else 0.0)) else 0.0
  if _t3757:
    _t3757 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
  _t3756 = 1.0 if _tr(_t3757) else 0.0
  if _t3756:
    _t3756 = 1.0 if _tr((0.0 if _tr(v_analysing) else 1.0)) else 0.0
  _t3755 = 1.0 if _tr(_t3756) else 0.0
  if _t3755:
    _t3758 = f_grid_signature()
    _t3755 = 1.0 if _tr((0.0 if abs(_t3758 - v_grid_sig) < 0.00001 else 1.0)) else 0.0
  if _tr(_t3755):
    if _tr(v_br_suppress_an):
      _t3761 = f_grid_signature()
      v_grid_sig = _t3761
      _t3760 = v_grid_sig
    else:
      _t3762 = f_start_analysis_ex(1.0)
      _t3760 = _t3762
    _t3759 = _t3760
  else:
    _t3759 = 0.0
  if _tr((0.0 if abs(v_slicer_link - v_last_link) < 0.00001 else 1.0)):
    v_last_link = v_slicer_link
    v_last_slicer_step = (-1.0)
    _t3764 = 1.0 if _tr((1.0 if abs(v_slicer_src - 1.0) < 0.00001 else 0.0)) else 0.0
    if _t3764:
      _t3764 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
    if _tr(_t3764):
      v_grid_sig = (-1.0)
      _t3766 = f_start_analysis_ex(1.0)
      _t3765 = _t3766
    else:
      _t3765 = 0.0
    _t3763 = _t3765
  else:
    _t3763 = 0.0
  if _tr(v_grid_pending):
    _t3768 = f_get_slicer_len()
    _t3769 = _t3768
    _t3770 = f_generate_slicer_sequence(_t3769)
    v_slicer_current_step = 0.0
    v_grid_pending = 0.0
    _t3767 = v_grid_pending
  else:
    _t3767 = 0.0
  if _tr((0.0 if abs(v_slicer_steps - v_last_steps) < 0.00001 else 1.0)):
    if _tr((1.0 if abs(v_slicer_mode - 1.0) < 0.00001 else 0.0)):
      _t3773 = (v_last_steps + 0.5)
      _t3774 = _floor(_t3773)
      _t3775 = _t3774
      _t3776 = (v_slicer_steps + 0.5)
      _t3777 = _floor(_t3776)
      _t3778 = _t3777
      _t3779 = f_slicer_resize(_t3775, _t3778)
      _t3772 = _t3779
    else:
      _t3772 = 0.0
    v_last_steps = v_slicer_steps
    _t3782 = 1.0 if _tr((1.0 if abs(v_ana_mode - 1.0) < 0.00001 else 0.0)) else 0.0
    if _t3782:
      _t3782 = 1.0 if _tr((1.0 if v_max_slices < 1.0 else 0.0)) else 0.0
    _t3781 = 1.0 if _tr(_t3782) else 0.0
    if _t3781:
      _t3781 = 1.0 if _tr((1.0 if abs(v_slicer_src - 0.0) < 0.00001 else 0.0)) else 0.0
    _t3780 = 1.0 if _tr(_t3781) else 0.0
    if _t3780:
      _t3780 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
    if _tr(_t3780):
      _t3784 = f_start_analysis_ex(1.0)
      _t3783 = _t3784
    else:
      _t3783 = 0.0
    _t3771 = _t3783
  else:
    _t3771 = 0.0
  if _tr((1.0 if v_preset_cur < 0.0 else 0.0)):
    _t3786 = (v_slicer_preset + 0.5)
    _t3787 = _floor(_t3786)
    _t3788 = (_t3787 - 1.0)
    _t3789 = min(3.0, _t3788)
    _t3790 = _t3789
    _t3791 = max(0.0, _t3790)
    v_preset_cur = _t3791
    v_last_preset = v_slicer_preset
    _t3785 = v_last_preset
  else:
    if _tr((0.0 if abs(v_slicer_preset - v_last_preset) < 0.00001 else 1.0)):
      v_last_preset = v_slicer_preset
      _t3793 = (v_slicer_preset + 0.5)
      _t3794 = _floor(_t3793)
      _t3795 = (_t3794 - 1.0)
      _t3796 = min(3.0, _t3795)
      _t3797 = _t3796
      _t3798 = max(0.0, _t3797)
      _t3799 = _t3798
      _t3800 = f_preset_switch(_t3799)
      _t3792 = _t3800
    else:
      _t3792 = 0.0
    _t3785 = _t3792
  _t3801 = 1.0 if _tr((0.0 if abs(v_max_slices - v_last_max_sl) < 0.00001 else 1.0)) else 0.0
  if _t3801:
    _t3801 = 1.0 if _tr((0.0 if abs(v_active_control - 48.0) < 0.00001 else 1.0)) else 0.0
  if _tr(_t3801):
    v_last_max_sl = v_max_slices
    if _tr((1.0 if v_length > 0.0 else 0.0)):
      _t3804 = f_start_analysis_ex(1.0)
      _t3803 = _t3804
    else:
      _t3803 = 0.0
    _t3802 = _t3803
  else:
    _t3802 = 0.0
  _t3807 = 1.0 if _tr((1.0 if v_an_prev_state >= 3.0 else 0.0)) else 0.0
  if _t3807:
    _t3807 = 1.0 if _tr((1.0 if v_an_prev_state <= 6.0 else 0.0)) else 0.0
  _t3806 = 1.0 if _tr(_t3807) else 0.0
  if _t3806:
    _t3808 = 1.0 if _tr((1.0 if v_state < 3.0 else 0.0)) else 0.0
    if not _t3808:
      _t3808 = 1.0 if _tr((1.0 if v_state > 6.0 else 0.0)) else 0.0
    _t3806 = 1.0 if _tr(_t3808) else 0.0
  _t3805 = 1.0 if _tr(_t3806) else 0.0
  if _t3805:
    _t3805 = 1.0 if _tr((0.0 if abs(v_state - 8.0) < 0.00001 else 1.0)) else 0.0
  if _tr(_t3805):
    v_an_exit_pending = 1.0
    _t3809 = v_an_exit_pending
  else:
    _t3809 = 0.0
  v_an_prev_state = v_state
  if _tr((0.0 if abs(v_an_prev_hist - v_active_history_idx) < 0.00001 else 1.0)):
    _t3811 = 1.0 if _tr((1.0 if v_state < 3.0 else 0.0)) else 0.0
    if not _t3811:
      _t3811 = 1.0 if _tr((1.0 if v_state > 6.0 else 0.0)) else 0.0
    if _tr(_t3811):
      v_an_exit_pending = 1.0
      _t3812 = v_an_exit_pending
    else:
      _t3812 = 0.0
    v_an_prev_hist = v_active_history_idx
    _t3810 = v_an_prev_hist
  else:
    _t3810 = 0.0
  _t3814 = 1.0 if _tr(v_an_exit_pending) else 0.0
  if _t3814:
    _t3814 = 1.0 if _tr((0.0 if _tr(v_cm_active) else 1.0)) else 0.0
  _t3813 = 1.0 if _tr(_t3814) else 0.0
  if _t3813:
    _t3813 = 1.0 if _tr((0.0 if abs(v_state - 8.0) < 0.00001 else 1.0)) else 0.0
  if _tr(_t3813):
    v_an_exit_pending = 0.0
    v_an_wrap_pending = 0.0
    if _tr((1.0 if v_length > 0.0 else 0.0)):
      _t3817 = f_start_analysis_ex(1.0)
      _t3816 = _t3817
    else:
      _t3816 = 0.0
    _t3815 = _t3816
  else:
    _t3815 = 0.0
  _t3819 = 1.0 if _tr(v_an_wrap_pending) else 0.0
  if _t3819:
    _t3819 = 1.0 if _tr((0.0 if _tr(v_cm_active) else 1.0)) else 0.0
  _t3818 = 1.0 if _tr(_t3819) else 0.0
  if _t3818:
    _t3818 = 1.0 if _tr((0.0 if _tr(v_analysing) else 1.0)) else 0.0
  if _tr(_t3818):
    v_an_wrap_pending = 0.0
    _t3823 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
    if _t3823:
      _t3823 = 1.0 if _tr((1.0 if v_state >= 3.0 else 0.0)) else 0.0
    _t3822 = 1.0 if _tr(_t3823) else 0.0
    if _t3822:
      _t3822 = 1.0 if _tr((1.0 if v_state <= 6.0 else 0.0)) else 0.0
    _t3821 = 1.0 if _tr(_t3822) else 0.0
    if _t3821:
      _t3824 = 1.0 if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)) else 0.0
      if not _t3824:
        _t3824 = 1.0 if _tr((1.0 if v_smp_mode > 0.0 else 0.0)) else 0.0
      _t3821 = 1.0 if _tr(_t3824) else 0.0
    if _tr(_t3821):
      _t3826 = f_start_analysis_ex(1.0)
      _t3825 = _t3826
    else:
      _t3825 = 0.0
    _t3820 = _t3825
  else:
    _t3820 = 0.0
  _t3827 = v_loop_start
  _t3828 = _floor(_t3827)
  _t3831 = (_t3828 * 3.0)
  _t3829 = v_loop_width
  _t3830 = _floor(_t3829)
  v_an_win_sig = ((_t3831 + (_t3830 * 7.0)) + (v_length * 13.0))
  if _tr((0.0 if abs(v_an_win_sig - v_an_win_last) < 0.00001 else 1.0)):
    v_an_win_last = v_an_win_sig
    if _tr(v_br_suppress_an):
      v_br_suppress_an = 0.0
      v_an_win_pend = 0.0
      if _tr((1.0 if abs(v_slicer_src - 1.0) < 0.00001 else 0.0)):
        _t3835 = f_grid_signature()
        v_grid_sig = _t3835
        _t3834 = v_grid_sig
      else:
        _t3834 = 0.0
      _t3833 = _t3834
    else:
      _t3836 = _time()
      v_an_win_t = (_t3836 + 0.25)
      v_an_win_pend = 1.0
      _t3833 = v_an_win_pend
    _t3832 = _t3833
  else:
    _t3832 = 0.0
  _t3839 = 1.0 if _tr(v_an_win_pend) else 0.0
  if _t3839:
    _t3840 = _time()
    _t3839 = 1.0 if _tr((1.0 if _t3840 >= v_an_win_t else 0.0)) else 0.0
  _t3838 = 1.0 if _tr(_t3839) else 0.0
  if _t3838:
    _t3838 = 1.0 if _tr((0.0 if _tr(v_cm_active) else 1.0)) else 0.0
  _t3837 = 1.0 if _tr(_t3838) else 0.0
  if _t3837:
    _t3837 = 1.0 if _tr((0.0 if abs(v_state - 8.0) < 0.00001 else 1.0)) else 0.0
  if _tr(_t3837):
    v_an_win_pend = 0.0
    _t3842 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
    if _t3842:
      _t3843 = 1.0 if _tr((1.0 if abs(v_slicer_src - 1.0) < 0.00001 else 0.0)) else 0.0
      if _t3843:
        _t3843 = 1.0 if _tr((0.0 if _tr(v_src_auto) else 1.0)) else 0.0
      _t3842 = 1.0 if _tr((0.0 if _tr(_t3843) else 1.0)) else 0.0
    if _tr(_t3842):
      _t3845 = f_start_analysis_ex(1.0)
      _t3844 = _t3845
    else:
      _t3844 = 0.0
    _t3841 = _t3844
  else:
    _t3841 = 0.0
  if _tr(v_det_chg):
    v_det_chg = 0.0
    _t3850 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
    if _t3850:
      _t3850 = 1.0 if _tr((0.0 if _tr(v_analysing) else 1.0)) else 0.0
    _t3849 = 1.0 if _tr(_t3850) else 0.0
    if _t3849:
      _t3849 = 1.0 if _tr((0.0 if _tr(v_cm_active) else 1.0)) else 0.0
    _t3848 = 1.0 if _tr(_t3849) else 0.0
    if _t3848:
      _t3848 = 1.0 if _tr((0.0 if abs(v_state - 8.0) < 0.00001 else 1.0)) else 0.0
    _t3847 = 1.0 if _tr(_t3848) else 0.0
    if _t3847:
      _t3851 = 1.0 if _tr((1.0 if abs(v_slicer_src - 1.0) < 0.00001 else 0.0)) else 0.0
      if _t3851:
        _t3851 = 1.0 if _tr((0.0 if _tr(v_src_auto) else 1.0)) else 0.0
      _t3847 = 1.0 if _tr((0.0 if _tr(_t3851) else 1.0)) else 0.0
    if _tr(_t3847):
      _t3853 = f_start_analysis_ex(1.0)
      _t3852 = _t3853
    else:
      _t3852 = 0.0
    _t3846 = _t3852
  else:
    _t3846 = 0.0
  if _tr((1.0 if abs(v_analysing - 1.0) < 0.00001 else 0.0)):
    _t3855 = (v_samplesblock * 8.0)
    _t3856 = _floor(_t3855)
    _t3857 = _t3856
    _t3858 = max(1024.0, _t3857)
    v_ana_budget = _t3858
    v_i = 0.0
    if _tr(v_wp_scan):
      _t3859 = 0.0
    else:
      _t3860 = v_loop_start
      _t3861 = _floor(_t3860)
      _t3859 = _t3861
    v_odf_ls = _t3859
    if _tr(v_wp_scan):
      _t3863 = v_length
      _t3864 = _floor(_t3863)
      _t3865 = _t3864
      _t3866 = max(1.0, _t3865)
      _t3862 = _t3866
    else:
      _t3867 = v_loop_width
      _t3868 = _floor(_t3867)
      _t3869 = _t3868
      _t3870 = max(1.0, _t3869)
      _t3862 = _t3870
    v_odf_lw = _t3862
    _t3871 = 0
    while True:
      _t3872 = 1.0 if _tr((1.0 if v_i < v_ana_budget else 0.0)) else 0.0
      if _t3872:
        _t3872 = 1.0 if _tr((1.0 if v_ana_k < v_ana_end else 0.0)) else 0.0
      if not _tr(_t3872): break
      if _tr((1.0 if v_ana_k < v_odf_ls else 0.0)):
        _t3873 = (v_odf_ls + _mod((v_odf_lw - _mod((v_odf_ls - v_ana_k), v_odf_lw)), v_odf_lw))
      else:
        _t3873 = v_ana_k
      v_odf_ix = _t3873
      v_dt_xl = _mget(v_left_buf + v_odf_ix)
      v_dt_xr = _mget(v_right_buf + v_odf_ix)
      _t3874 = v_dt_xl
      _t3875 = abs(_t3874)
      _t3876 = _t3875
      _t3877 = v_dt_xr
      _t3878 = abs(_t3877)
      _t3879 = _t3878
      _t3880 = max(_t3876, _t3879)
      v_dv_a = _t3880
      _t3881 = v_dv_a
      _t3882 = (v_dv_f * v_dv_rf)
      _t3883 = max(_t3881, _t3882)
      v_dv_f = _t3883
      if _tr((1.0 if v_dv_hold > 0.0 else 0.0)):
        v_dv_hold = (v_dv_hold - 1.0)
        _t3884 = v_dv_hold
      else:
        _t3884 = 0.0
      v_dt_x = ((v_dt_xl + v_dt_xr) * 0.5)
      _t3885 = 1.0 if _tr((1.0 if v_dt_gl < 0.0 else 0.0)) else 0.0
      if _t3885:
        _t3885 = 1.0 if _tr((1.0 if abs(v_dt_hc - 0.0) < 0.00001 else 0.0)) else 0.0
      if _tr(_t3885):
        v_dt_b1 = v_dt_x
        v_dt_b2 = v_dt_x
        _t3886 = v_dt_b2
      else:
        _t3886 = 0.0
      v_dt_b1 = (v_dt_b1 + (v_odf_a_lo * (v_dt_x - v_dt_b1)))
      v_dt_b2 = (v_dt_b2 + (v_odf_a_mid * (v_dt_x - v_dt_b2)))
      _t3887 = v_dt_b1
      _t3888 = abs(_t3887)
      _t3889 = _t3888
      _t3890 = (v_dt_el * v_dt_rl)
      _t3891 = max(_t3889, _t3890)
      v_dt_el = _t3891
      _t3892 = (v_dt_b2 - v_dt_b1)
      _t3893 = abs(_t3892)
      _t3894 = _t3893
      _t3895 = (v_dt_em * v_dt_rm)
      _t3896 = max(_t3894, _t3895)
      v_dt_em = _t3896
      _t3897 = (v_dt_x - v_dt_b2)
      _t3898 = abs(_t3897)
      _t3899 = _t3898
      _t3900 = (v_dt_eh * v_dt_rh)
      _t3901 = max(_t3899, _t3900)
      v_dt_eh = _t3901
      if _tr((1.0 if v_dt_tr > 0.0 else 0.0)):
        _t3903 = v_dt_pk
        _t3904 = v_dv_a
        _t3905 = max(_t3903, _t3904)
        v_dt_pk = _t3905
        _t3902 = v_dt_pk
      else:
        _t3902 = 0.0
      if _tr((1.0 if v_ana_k >= v_odf_ls else 0.0)):
        if _tr((1.0 if v_dv_a > v_ana_max_peak else 0.0)):
          v_ana_max_peak = v_dv_a
          _t3907 = v_ana_max_peak
        else:
          _t3907 = 0.0
        _t3906 = _t3907
      else:
        _t3906 = 0.0
      v_dt_hc = (v_dt_hc + 1.0)
      if _tr((1.0 if v_dt_hc >= v_odf_hop else 0.0)):
        v_dt_hc = 0.0
        _t3909 = f_dt_hop()
        _t3908 = _t3909
      else:
        _t3908 = 0.0
      v_ana_k = (v_ana_k + 1.0)
      v_i = (v_i + 1.0)
      _t3871 += 1
      if _t3871 > 1000000: break
    _t3910 = 1.0 if _tr((1.0 if v_ana_k >= v_ana_end else 0.0)) else 0.0
    if _t3910:
      _t3910 = 1.0 if _tr((1.0 if v_dt_tr > 0.0 else 0.0)) else 0.0
    if _tr(_t3910):
      v_dt_tr = 0.0
      _t3912 = f_dt_emit()
      _t3911 = _t3912
    else:
      _t3911 = 0.0
    if _tr((1.0 if v_ana_k >= v_ana_end else 0.0)):
      v_dv_j = 0.0
      v_dv_m = 0.0
      v_dv_lim = (v_det_rel * v_ana_max_peak)
      for _t3914 in range(max(0, int(v_cand_n))):
        if _tr((1.0 if _mget(v_cand_s + v_dv_j) >= v_dv_lim else 0.0)):
          _t3916 = _ix(v_cand_k + v_dv_m)
          _t3917 = _mget(v_cand_k + v_dv_j)
          _mset(_t3916, _t3917)
          _t3918 = _ix(v_cand_s + v_dv_m)
          _t3919 = _mget(v_cand_s + v_dv_j)
          _mset(_t3918, _t3919)
          _t3920 = _ix(v_cand_v + v_dv_m)
          _t3921 = _mget(v_cand_v + v_dv_j)
          _mset(_t3920, _t3921)
          _t3922 = _ix(v_cand_ok + v_dv_m)
          _t3923 = 1.0
          _mset(_t3922, _t3923)
          v_dv_m = (v_dv_m + 1.0)
          _t3915 = v_dv_m
        else:
          _t3915 = 0.0
        v_dv_j = (v_dv_j + 1.0)
      v_cand_n = v_dv_m
      if _tr(v_wp_scan):
        _t3925 = v_cand_n
        _t3926 = v_wp_max
        _t3927 = min(_t3925, _t3926)
        v_wp_mn = _t3927
        v_dv_j = 0.0
        for _t3928 in range(max(0, int(v_wp_mn))):
          _t3929 = _ix(v_wp_mk + v_dv_j)
          _t3930 = _mget(v_cand_k + v_dv_j)
          _mset(_t3929, _t3930)
          v_dv_j = (v_dv_j + 1.0)
        v_wp_scan = 0.0
        v_analysing = 0.0
        v_wp_ri = 0.0
        v_wp_phase = 3.0
        _t3924 = v_wp_phase
      else:
        v_an_ns = v_cand_n
        v_an_nr = v_cand_n
        v_an_ne = v_cand_n
        _t3931 = 1.0 if _tr((1.0 if abs(v_slicer_src - 0.0) < 0.00001 else 0.0)) else 0.0
        if not _t3931:
          _t3931 = 1.0 if _tr(v_src_auto) else 0.0
        if _tr(_t3931):
          _t3933 = v_det_cap
          _t3934 = (v_max_slices + 0.5)
          _t3935 = _floor(_t3934)
          _t3936 = _t3935
          _t3937 = min(_t3933, _t3936)
          _t3932 = _t3937
        else:
          _t3932 = 0.0
        v_an_n = _t3932
        v_an_wasg = (1.0 if abs(v_slicer_src - 1.0) < 0.00001 else 0.0)
        v_sel_n = 0.0
        v_ana_mode = 0.0
        if _tr(v_det_strict):
          _t3938 = (1.0 if v_an_ne < 1.0 else 0.0)
        else:
          _t3939 = 1.0 if _tr((1.0 if v_an_ne < 2.0 else 0.0)) else 0.0
          if not _t3939:
            _t3940 = 1.0 if _tr((1.0 if v_an_n >= 1.0 else 0.0)) else 0.0
            if _t3940:
              _t3940 = 1.0 if _tr((1.0 if v_an_ne < (0.12 * v_an_n) else 0.0)) else 0.0
            _t3939 = 1.0 if _tr(_t3940) else 0.0
          _t3938 = _t3939
        if _tr(_t3938):
          if _tr(v_det_strict):
            _t3943 = 1.0 if _tr(v_src_auto) else 0.0
            if _t3943:
              _t3943 = 1.0 if _tr(v_an_wasg) else 0.0
            if _tr(_t3943):
              v_slicer_src = 0.0
              v_slicer_src = 0.0
              v_last_slicer_src = 0.0
              _t3944 = v_last_slicer_src
            else:
              _t3944 = 0.0
            if _tr(v_an_keep):
              v_analysing = 0.0
              _t3945 = v_analysing
            else:
              v_an_keep = 0.0
              _t3946 = f_an_commit()
              _t3945 = _t3946
            _t3942 = _t3945
          else:
            if _tr(v_src_auto):
              v_an_osub = v_grid_sub
              if _tr((1.0 if v_an_n >= 1.0 else 0.0)):
                _t3949 = v_an_n
                _t3950 = f_grid_pick(_t3949)
                _t3948 = _t3950
              else:
                _t3948 = 0.0
              v_slicer_src = 1.0
              v_slicer_src = 1.0
              v_last_slicer_src = 1.0
              v_last_grid_sub = v_grid_sub
              v_grid_sub = v_grid_sub
              _t3952 = 1.0 if _tr((0.0 if _tr(v_an_wasg) else 1.0)) else 0.0
              if not _t3952:
                _t3952 = 1.0 if _tr((0.0 if abs(v_grid_sub - v_an_osub) < 0.00001 else 1.0)) else 0.0
              _t3951 = 1.0 if _tr(_t3952) else 0.0
              if not _t3951:
                _t3953 = f_grid_signature()
                _t3951 = 1.0 if _tr((0.0 if abs(_t3953 - v_grid_sig) < 0.00001 else 1.0)) else 0.0
              if _tr(_t3951):
                _t3955 = f_grid_build()
                _t3954 = _t3955
              else:
                v_analysing = 0.0
                _t3954 = v_analysing
              v_ana_mode = 2.0
              v_an_keep = 0.0
              _t3947 = v_an_keep
            else:
              if _tr((1.0 if v_an_n >= 1.0 else 0.0)):
                _t3956 = v_an_n
              else:
                _t3957 = (v_slicer_steps + 0.5)
                _t3958 = _floor(_t3957)
                _t3959 = _t3958
                _t3960 = max(2.0, _t3959)
                _t3956 = _t3960
              _t3961 = _t3956
              _t3962 = f_an_fractions(_t3961)
              _t3963 = f_an_commit()
              _t3947 = _t3963
            _t3942 = _t3947
          _t3941 = _t3942
        else:
          _t3964 = 1.0 if _tr(v_src_auto) else 0.0
          if _t3964:
            _t3964 = 1.0 if _tr(v_an_wasg) else 0.0
          if _tr(_t3964):
            v_slicer_src = 0.0
            v_slicer_src = 0.0
            v_last_slicer_src = 0.0
            v_an_keep = 0.0
            _t3965 = v_an_keep
          else:
            _t3965 = 0.0
          if _tr((1.0 if v_an_n >= 1.0 else 0.0)):
            _t3967 = v_an_n
            _t3968 = v_max_transients
            _t3969 = min(_t3967, _t3968)
            _t3966 = _t3969
          else:
            _t3970 = v_det_cap
            _t3971 = v_max_transients
            _t3972 = min(_t3970, _t3971)
            _t3966 = _t3972
          v_an_target = _t3966
          _t3975 = v_loop_width
          _t3973 = v_an_target
          _t3974 = max(1.0, _t3973)
          _t3976 = _div(_t3975, _t3974)
          _t3977 = max(1.0, _t3976)
          v_an_gapm = _t3977
          _t3978 = (0.5 * v_an_gapm)
          _t3979 = _floor(_t3978)
          v_an_dmin = _t3979
          v_dv_j = 0.0
          for _t3980 in range(max(0, int(v_cand_n))):
            _t3981 = _ix(v_cand_v + v_dv_j)
            _t3982 = _div(_mget(v_cand_s + v_dv_j), v_ana_max_peak)
            _t3983 = max(0.001, _t3982)
            _t3984 = _t3983
            _t3985 = _log10(_t3984)
            _t3986 = (_mget(_t3981) + (3.0 * _t3985))
            _mset(_t3981, _t3986)
            v_dv_j = (v_dv_j + 1.0)
          v_an_done = 0.0
          v_analysing = 3.0
          _t3941 = v_analysing
        _t3924 = _t3941
      _t3913 = _t3924
    else:
      _t3913 = 0.0
    _t3854 = _t3913
  else:
    if _tr((1.0 if abs(v_analysing - 3.0) < 0.00001 else 0.0)):
      if _tr((1.0 if v_an_n >= 1.0 else 0.0)):
        _t3989 = v_an_n
        _t3990 = v_max_transients
        _t3991 = min(_t3989, _t3990)
        _t3988 = _t3991
      else:
        _t3992 = v_det_cap
        _t3993 = v_max_transients
        _t3994 = min(_t3992, _t3993)
        _t3988 = _t3994
      v_an_target = _t3988
      v_an_r = 0.0
      _t3995 = 0
      while True:
        _t3996 = 1.0 if _tr((1.0 if v_an_r < 2.0 else 0.0)) else 0.0
        if _t3996:
          _t3996 = 1.0 if _tr((0.0 if _tr(v_an_done) else 1.0)) else 0.0
        if not _tr(_t3996): break
        if _tr((1.0 if v_sel_n >= v_an_target else 0.0)):
          v_an_done = 1.0
          _t3997 = v_an_done
        else:
          v_an_bj = (-1.0)
          v_an_bs = (-1000000.0)
          v_an_j = 0.0
          _t3998 = 0
          while True:
            if not _tr((1.0 if v_an_j < v_cand_n else 0.0)): break
            if _tr(_mget(v_cand_ok + v_an_j)):
              v_an_d = v_an_gapm
              v_an_q = 0.0
              _t4000 = 0
              while True:
                if not _tr((1.0 if v_an_q < v_sel_n else 0.0)): break
                _t4001 = v_an_d
                _t4002 = (_mget(v_cand_k + v_an_j) - _mget(v_sel_k + v_an_q))
                _t4003 = abs(_t4002)
                _t4004 = _t4003
                _t4005 = min(_t4001, _t4004)
                v_an_d = _t4005
                v_an_q = (v_an_q + 1.0)
                _t4000 += 1
                if _t4000 > 1000000: break
              v_an_sc = (_mget(v_cand_v + v_an_j) + _div((3.0 * v_an_d), v_an_gapm))
              if _tr((1.0 if v_an_sc > v_an_bs else 0.0)):
                v_an_bs = v_an_sc
                v_an_bj = v_an_j
                _t4006 = v_an_bj
              else:
                _t4006 = 0.0
              _t3999 = _t4006
            else:
              _t3999 = 0.0
            v_an_j = (v_an_j + 1.0)
            _t3998 += 1
            if _t3998 > 1000000: break
          if _tr((1.0 if v_an_bj < 0.0 else 0.0)):
            v_an_done = 1.0
            _t4007 = v_an_done
          else:
            v_an_kk = _mget(v_cand_k + v_an_bj)
            _t4008 = _ix(v_sel_k + v_sel_n)
            _t4011 = v_an_kk
            _t4009 = (v_srate * 0.001)
            _t4010 = _floor(_t4009)
            _t4012 = (_t4011 - _t4010)
            _t4013 = f_odf_refine(_t4012)
            _t4014 = _t4013
            _mset(_t4008, _t4014)
            _t4015 = _ix(v_sel_s + v_sel_n)
            _t4016 = _div(_mget(v_cand_v + v_an_bj), v_dt_cap)
            _t4017 = min(1.0, _t4016)
            _t4018 = _t4017
            _t4019 = max(0.01, _t4018)
            _t4020 = _t4019
            _mset(_t4015, _t4020)
            v_sel_n = (v_sel_n + 1.0)
            v_an_j = v_an_bj
            _t4021 = 0
            while True:
              _t4022 = 1.0 if _tr((1.0 if v_an_j >= 0.0 else 0.0)) else 0.0
              if _t4022:
                _t4022 = 1.0 if _tr((1.0 if (v_an_kk - _mget(v_cand_k + v_an_j)) < v_an_dmin else 0.0)) else 0.0
              if not _tr(_t4022): break
              _t4023 = _ix(v_cand_ok + v_an_j)
              _t4024 = 0.0
              _mset(_t4023, _t4024)
              v_an_j = (v_an_j - 1.0)
              _t4021 += 1
              if _t4021 > 1000000: break
            v_an_j = (v_an_bj + 1.0)
            _t4025 = 0
            while True:
              _t4026 = 1.0 if _tr((1.0 if v_an_j < v_cand_n else 0.0)) else 0.0
              if _t4026:
                _t4026 = 1.0 if _tr((1.0 if (_mget(v_cand_k + v_an_j) - v_an_kk) < v_an_dmin else 0.0)) else 0.0
              if not _tr(_t4026): break
              _t4027 = _ix(v_cand_ok + v_an_j)
              _t4028 = 0.0
              _mset(_t4027, _t4028)
              v_an_j = (v_an_j + 1.0)
              _t4025 += 1
              if _t4025 > 1000000: break
            _t4007 = 0.0
          _t3997 = _t4007
        v_an_r = (v_an_r + 1.0)
        _t3995 += 1
        if _t3995 > 1000000: break
      if _tr(v_an_done):
        _t4030 = f_an_sortfill()
        _t4031 = f_an_commit()
        _t4029 = _t4031
      else:
        _t4029 = 0.0
      _t3987 = _t4029
    else:
      _t3987 = 0.0
    _t3854 = _t3987
  _t4032 = f_wp_tick()
  _t4033 = (v_manual_id + 0.5)
  _t4034 = _floor(_t4033)
  v_manual_id = _t4034
  if _tr((1.0 if v_manual_id < 0.0 else 0.0)):
    v_manual_id = 0.0
    _t4035 = v_manual_id
  else:
    if _tr((1.0 if v_manual_id > 8.0 else 0.0)):
      v_manual_id = 8.0
      _t4036 = v_manual_id
    else:
      _t4036 = 0.0
    _t4035 = _t4036
  _t4038 = 1.0 if _tr((1.0 if abs(v_manual_id - 0.0) < 0.00001 else 0.0)) else 0.0
  if _t4038:
    _t4038 = 1.0 if _tr((1.0 if v_saved_manual_id > 0.0 else 0.0)) else 0.0
  _t4037 = 1.0 if _tr(_t4038) else 0.0
  if _t4037:
    _t4037 = 1.0 if _tr((1.0 if v_saved_manual_id <= 8.0 else 0.0)) else 0.0
  if _tr(_t4037):
    v_manual_id = v_saved_manual_id
    v_manual_id = v_manual_id
    _t4039 = v_manual_id
  else:
    _t4039 = 0.0
  v_saved_manual_id = v_manual_id
  if _tr((1.0 if v_manual_id > 0.0 else 0.0)):
    _t4040 = v_manual_id
  else:
    _t4040 = 1.0
  v_instance_id = _t4040
  v_instance_alias = v_instance_id
  v_inst_idx = (v_instance_id - 1.0)
  _t4041 = _ix((100.0 + v_inst_idx))
  _t4042 = v_instance_id
  _gset(_t4041, _t4042)
  _t4043 = _ix((130.0 + v_inst_idx))
  _t4044 = _time()
  _t4045 = _t4044
  _gset(_t4043, _t4045)
  _t4046 = _ix((160.0 + v_inst_idx))
  _t4047 = v_looper_hue
  _gset(_t4046, _t4047)
  v_param_clear_i = 0.0
  for _t4048 in range(max(0, int(3.0))):
    v_param_clear_base = (110000.0 + (((v_inst_idx * 3.0) + v_param_clear_i) * 60.0))
    _t4049 = _ix((v_param_clear_base + 59.0))
    _t4050 = 0.0
    _gset(_t4049, _t4050)
    v_param_clear_i = (v_param_clear_i + 1.0)
  v_p = 0.0
  for _t4051 in range(max(0, int(3.0))):
    v_gmem_base = ((1000.0 + (v_inst_idx * 600.0)) + (v_p * 200.0))
    v_cmd = _gget((v_gmem_base + 48.0))
    if _tr((1.0 if v_cmd > 0.0 else 0.0)):
      v_cmd_arg = _gget((v_gmem_base + 49.0))
      v_cmd_lag = 0.0
      if _tr((1.0 if abs(_gget(951.0) - (v_gmem_base + 48.0)) < 0.00001 else 0.0)):
        _t4054 = _time()
        v_cmd_lag = (_t4054 - _gget(950.0))
        _t4055 = 1.0 if _tr((1.0 if v_cmd_lag > 0.0 else 0.0)) else 0.0
        if _t4055:
          _t4055 = 1.0 if _tr((1.0 if v_cmd_lag < 0.1 else 0.0)) else 0.0
        if _tr(_t4055):
          _t4057 = (v_cmd_lag * v_srate)
          _t4058 = _floor(_t4057)
          _t4056 = _t4058
        else:
          _t4056 = 0.0
        v_cmd_lag = _t4056
        _t4059 = _ix(951.0)
        _t4060 = 0.0
        _gset(_t4059, _t4060)
        _t4053 = _t4060
      else:
        _t4053 = 0.0
      if _tr((1.0 if abs(v_cmd - 12.0) < 0.00001 else 0.0)):
        v_req_part = (v_p + 1.0)
        if _tr((1.0 if abs(v_req_part - v_active_part) < 0.00001 else 0.0)):
          v_pending_part_switch = 0.0
          _t4062 = v_pending_part_switch
        else:
          _t4063 = 1.0 if _tr(v_pending_part_switch) else 0.0
          if _t4063:
            _t4063 = 1.0 if _tr((1.0 if abs(v_target_part - v_req_part) < 0.00001 else 0.0)) else 0.0
          if _tr(_t4063):
            v_pending_part_switch = 0.0
            _t4064 = v_pending_part_switch
          else:
            if _tr((1.0 if v_length > 0.0 else 0.0)):
              v_target_part = v_req_part
              v_pending_part_switch = 1.0
              _t4065 = v_pending_part_switch
            else:
              _t4066 = v_req_part
              _t4067 = f_switch_part(_t4066)
              _t4065 = _t4067
            _t4064 = _t4065
          _t4062 = _t4064
        _t4061 = _t4062
      else:
        if _tr((0.0 if abs(v_p - (v_active_part - 1.0)) < 0.00001 else 1.0)):
          _t4069 = (v_p + 1.0)
          _t4070 = f_switch_part(_t4069)
          _t4068 = _t4070
        else:
          _t4068 = 0.0
        if _tr((1.0 if abs(v_cmd - 1.0) < 0.00001 else 0.0)):
          _t4073 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
          if _t4073:
            _t4073 = 1.0 if _tr((0.0 if abs(v_state - 1.0) < 0.00001 else 1.0)) else 0.0
          _t4072 = 1.0 if _tr(_t4073) else 0.0
          if _t4072:
            _t4072 = 1.0 if _tr((0.0 if abs(v_state - 8.0) < 0.00001 else 1.0)) else 0.0
          if _tr(_t4072):
            if _tr((1.0 if abs(v_state - 3.0) < 0.00001 else 0.0)):
              _t4075 = 2.0
            else:
              _t4075 = 3.0
            v_state_target = _t4075
            _t4074 = v_state_target
          else:
            v_rec_cmd = 1.0
            v_rec_lag_pend = v_cmd_lag
            _t4074 = v_rec_lag_pend
          _t4071 = _t4074
        else:
          if _tr((1.0 if abs(v_cmd - 2.0) < 0.00001 else 0.0)):
            _t4077 = f_do_clear(0.0)
            v_state_target = 0.0
            _t4076 = v_state_target
          else:
            if _tr((1.0 if abs(v_cmd - 3.0) < 0.00001 else 0.0)):
              _t4079 = 1.0 if _tr((1.0 if abs(v_state - 0.0) < 0.00001 else 0.0)) else 0.0
              if not _t4079:
                _t4079 = 1.0 if _tr((1.0 if abs(v_state - 7.0) < 0.00001 else 0.0)) else 0.0
              if _tr(_t4079):
                _t4080 = 2.0
              else:
                _t4080 = 0.0
              v_state_target = _t4080
              _t4078 = v_state_target
            else:
              if _tr((1.0 if abs(v_cmd - 4.0) < 0.00001 else 0.0)):
                v_rev_on = (0.0 if _tr(v_rev_on) else 1.0)
                v_rev_on = v_rev_on
                _t4081 = v_rev_on
              else:
                if _tr((1.0 if abs(v_cmd - 5.0) < 0.00001 else 0.0)):
                  v_pingpong_on = (0.0 if _tr(v_pingpong_on) else 1.0)
                  v_pingpong_on = v_pingpong_on
                  _t4082 = v_pingpong_on
                else:
                  if _tr((1.0 if abs(v_cmd - 6.0) < 0.00001 else 0.0)):
                    if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)):
                      _t4084 = 0.0
                    else:
                      _t4084 = 1.0
                    v_play_mode = _t4084
                    v_play_mode = v_play_mode
                    if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)):
                      v_cloud_on = 0.0
                      v_cloud_on = 0.0
                      _t4085 = v_cloud_on
                    else:
                      _t4085 = 0.0
                    _t4083 = _t4085
                  else:
                    if _tr((1.0 if abs(v_cmd - 7.0) < 0.00001 else 0.0)):
                      v_cloud_on = (0.0 if _tr(v_cloud_on) else 1.0)
                      v_cloud_on = v_cloud_on
                      _t4087 = 1.0 if _tr(v_cloud_on) else 0.0
                      if _t4087:
                        _t4087 = 1.0 if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)) else 0.0
                      if _tr(_t4087):
                        v_play_mode = 0.0
                        v_play_mode = 0.0
                        _t4088 = v_play_mode
                      else:
                        _t4088 = 0.0
                      _t4086 = _t4088
                    else:
                      if _tr((1.0 if abs(v_cmd - 8.0) < 0.00001 else 0.0)):
                        v_link_on = (0.0 if _tr(v_link_on) else 1.0)
                        v_link_on = v_link_on
                        _t4089 = v_link_on
                      else:
                        if _tr((1.0 if abs(v_cmd - 9.0) < 0.00001 else 0.0)):
                          if _tr((1.0 if abs(v_state - 4.0) < 0.00001 else 0.0)):
                            _t4091 = 2.0
                          else:
                            _t4091 = 4.0
                          v_state_target = _t4091
                          _t4090 = v_state_target
                        else:
                          if _tr((1.0 if abs(v_cmd - 10.0) < 0.00001 else 0.0)):
                            if _tr((1.0 if abs(v_state - 5.0) < 0.00001 else 0.0)):
                              _t4093 = 2.0
                            else:
                              _t4093 = 5.0
                            v_state_target = _t4093
                            _t4092 = v_state_target
                          else:
                            if _tr((1.0 if abs(v_cmd - 11.0) < 0.00001 else 0.0)):
                              _t4095 = f_do_clear(1.0)
                              v_state_target = 0.0
                              _t4094 = v_state_target
                            else:
                              if _tr((1.0 if abs(v_cmd - 13.0) < 0.00001 else 0.0)):
                                if _tr((1.0 if abs(v_state - 6.0) < 0.00001 else 0.0)):
                                  _t4097 = 2.0
                                else:
                                  _t4097 = 6.0
                                v_state_target = _t4097
                                _t4096 = v_state_target
                              else:
                                if _tr((1.0 if abs(v_cmd - 14.0) < 0.00001 else 0.0)):
                                  _t4099 = f_undo_state()
                                  _t4098 = _t4099
                                else:
                                  if _tr((1.0 if abs(v_cmd - 15.0) < 0.00001 else 0.0)):
                                    _t4101 = f_redo_state()
                                    _t4100 = _t4101
                                  else:
                                    if _tr((1.0 if abs(v_cmd - 16.0) < 0.00001 else 0.0)):
                                      _t4103 = f_trigger_restart()
                                      _t4102 = _t4103
                                    else:
                                      if _tr((1.0 if abs(v_cmd - 17.0) < 0.00001 else 0.0)):
                                        _t4105 = f_do_clear(0.0)
                                        v_state_target = 1.0
                                        _t4106 = f_rx_announce()
                                        _t4104 = _t4106
                                      else:
                                        if _tr((1.0 if abs(v_cmd - 18.0) < 0.00001 else 0.0)):
                                          if _tr((1.0 if abs(v_play_mode - 2.0) < 0.00001 else 0.0)):
                                            _t4108 = 0.0
                                          else:
                                            _t4108 = 2.0
                                          v_play_mode = _t4108
                                          v_play_mode = v_play_mode
                                          if _tr((1.0 if abs(v_play_mode - 2.0) < 0.00001 else 0.0)):
                                            v_cloud_on = 0.0
                                            v_cloud_on = 0.0
                                            _t4109 = v_cloud_on
                                          else:
                                            _t4109 = 0.0
                                          _t4107 = _t4109
                                        else:
                                          if _tr((1.0 if abs(v_cmd - 19.0) < 0.00001 else 0.0)):
                                            v_auto_on = (0.0 if _tr(v_auto_on) else 1.0)
                                            _t4110 = v_auto_on
                                          else:
                                            if _tr((1.0 if abs(v_cmd - 20.0) < 0.00001 else 0.0)):
                                              v_st = v_cmd_arg
                                              _t4112 = v_st
                                              _t4113 = abs(_t4112)
                                              if _tr((1.0 if _t4113 < 0.0001 else 0.0)):
                                                v_st = 12.0
                                                _t4114 = v_st
                                              else:
                                                _t4114 = 0.0
                                              _t4115 = (v_speed * _pow(2.0, _div(v_st, 12.0)))
                                              _t4116 = min(100.0, _t4115)
                                              _t4117 = _t4116
                                              _t4118 = max(0.01, _t4117)
                                              v_speed = _t4118
                                              v_speed = v_speed
                                              _t4111 = v_speed
                                            else:
                                              if _tr((1.0 if abs(v_cmd - 21.0) < 0.00001 else 0.0)):
                                                v_st = v_cmd_arg
                                                _t4120 = v_st
                                                _t4121 = abs(_t4120)
                                                if _tr((1.0 if _t4121 < 0.0001 else 0.0)):
                                                  v_st = 12.0
                                                  _t4122 = v_st
                                                else:
                                                  _t4122 = 0.0
                                                _t4123 = (-48.0)
                                                _t4124 = (v_pitch + v_st)
                                                _t4125 = min(48.0, _t4124)
                                                _t4126 = _t4125
                                                _t4127 = max(_t4123, _t4126)
                                                v_pitch = _t4127
                                                v_pitch = v_pitch
                                                _t4119 = v_pitch
                                              else:
                                                if _tr((1.0 if abs(v_cmd - 22.0) < 0.00001 else 0.0)):
                                                  if _tr((1.0 if v_length > 0.0 else 0.0)):
                                                    v_loop_start = 0.0
                                                    v_loop_width = v_length
                                                    v_sync_hard_resync = 1.0
                                                    _t4129 = v_sync_hard_resync
                                                  else:
                                                    _t4129 = 0.0
                                                  _t4128 = _t4129
                                                else:
                                                  if _tr((1.0 if abs(v_cmd - 23.0) < 0.00001 else 0.0)):
                                                    if _tr((1.0 if v_loop_quant >= 9.0 else 0.0)):
                                                      _t4131 = 0.0
                                                    else:
                                                      _t4131 = (v_loop_quant + 1.0)
                                                    v_loop_quant = _t4131
                                                    v_loop_quant = v_loop_quant
                                                    if _tr(v_br_on):
                                                      _t4133 = f_br_refresh()
                                                      _t4132 = _t4133
                                                    else:
                                                      if _tr((1.0 if v_length > 0.0 else 0.0)):
                                                        _t4135 = v_loop_start
                                                        _t4136 = f_apply_quant_start(_t4135)
                                                        v_loop_start = _t4136
                                                        _t4137 = v_loop_width
                                                        _t4138 = v_loop_start
                                                        _t4139 = f_apply_quant_width(_t4137, _t4138)
                                                        v_loop_width = _t4139
                                                        v_sync_hard_resync = 1.0
                                                        _t4134 = v_sync_hard_resync
                                                      else:
                                                        _t4134 = 0.0
                                                      _t4132 = _t4134
                                                    _t4130 = _t4132
                                                  else:
                                                    if _tr((1.0 if abs(v_cmd - 24.0) < 0.00001 else 0.0)):
                                                      _t4141 = f_reset_all_params()
                                                      _t4140 = _t4141
                                                    else:
                                                      if _tr((1.0 if abs(v_cmd - 25.0) < 0.00001 else 0.0)):
                                                        _t4143 = f_x_arm(1.0)
                                                        _t4142 = _t4143
                                                      else:
                                                        if _tr((1.0 if abs(v_cmd - 26.0) < 0.00001 else 0.0)):
                                                          _t4145 = f_x_arm(2.0)
                                                          _t4144 = _t4145
                                                        else:
                                                          if _tr((1.0 if abs(v_cmd - 27.0) < 0.00001 else 0.0)):
                                                            _t4147 = f_x_arm(0.0)
                                                            _t4146 = _t4147
                                                          else:
                                                            if _tr((1.0 if abs(v_cmd - 28.0) < 0.00001 else 0.0)):
                                                              _t4149 = v_cmd_arg
                                                              _t4150 = f_x_adopt(_t4149)
                                                              _t4148 = _t4150
                                                            else:
                                                              if _tr((1.0 if abs(v_cmd - 29.0) < 0.00001 else 0.0)):
                                                                _t4152 = f_x_arm(3.0)
                                                                _t4151 = _t4152
                                                              else:
                                                                if _tr((1.0 if abs(v_cmd - 31.0) < 0.00001 else 0.0)):
                                                                  _t4154 = f_ld_begin()
                                                                  _t4153 = _t4154
                                                                else:
                                                                  if _tr((1.0 if abs(v_cmd - 32.0) < 0.00001 else 0.0)):
                                                                    _t4156 = f_ld_query()
                                                                    _t4155 = _t4156
                                                                  else:
                                                                    if _tr((1.0 if abs(v_cmd - 33.0) < 0.00001 else 0.0)):
                                                                      _t4158 = (0.0 if _tr(v_br_on) else 1.0)
                                                                      _t4159 = f_do_beat_repeat(_t4158)
                                                                      _t4157 = _t4159
                                                                    else:
                                                                      if _tr((1.0 if abs(v_cmd - 37.0) < 0.00001 else 0.0)):
                                                                        if _tr((1.0 if abs(v_cmd_arg - 1.0) < 0.00001 else 0.0)):
                                                                          _t4161 = 1.0
                                                                        else:
                                                                          if _tr((1.0 if abs(v_cmd_arg - 2.0) < 0.00001 else 0.0)):
                                                                            _t4162 = 0.0
                                                                          else:
                                                                            _t4162 = (0.0 if _tr(v_lp_mute) else 1.0)
                                                                          _t4161 = _t4162
                                                                        v_lp_mute = _t4161
                                                                        _t4160 = v_lp_mute
                                                                      else:
                                                                        if _tr((1.0 if abs(v_cmd - 38.0) < 0.00001 else 0.0)):
                                                                          if _tr((1.0 if abs(v_cmd_arg - 1.0) < 0.00001 else 0.0)):
                                                                            _t4164 = 1.0
                                                                          else:
                                                                            if _tr((1.0 if abs(v_cmd_arg - 2.0) < 0.00001 else 0.0)):
                                                                              _t4165 = 0.0
                                                                            else:
                                                                              if _tr((1.0 if v_warp_on >= 0.5 else 0.0)):
                                                                                _t4166 = 0.0
                                                                              else:
                                                                                _t4166 = 1.0
                                                                              _t4165 = _t4166
                                                                            _t4164 = _t4165
                                                                          v_warp_on = _t4164
                                                                          v_warp_on = v_warp_on
                                                                          _t4163 = v_warp_on
                                                                        else:
                                                                          if _tr((1.0 if abs(v_cmd - 34.0) < 0.00001 else 0.0)):
                                                                            _t4168 = v_cmd_arg
                                                                            _t4169 = f_dr_arm_target(_t4168)
                                                                            _t4167 = _t4169
                                                                          else:
                                                                            if _tr((1.0 if abs(v_cmd - 35.0) < 0.00001 else 0.0)):
                                                                              _t4171 = v_cmd_arg
                                                                              _t4172 = f_dr_arm_source(_t4171)
                                                                              _t4170 = _t4172
                                                                            else:
                                                                              if _tr((1.0 if abs(v_cmd - 36.0) < 0.00001 else 0.0)):
                                                                                _t4174 = v_cmd_arg
                                                                                _t4175 = f_dr_commit_begin(_t4174)
                                                                                _t4173 = _t4175
                                                                              else:
                                                                                if _tr((1.0 if abs(v_cmd - 30.0) < 0.00001 else 0.0)):
                                                                                  v_x_free = (1.0 if v_cmd_arg > 0.0 else 0.0)
                                                                                  _t4177 = f_x_arm(4.0)
                                                                                  _t4176 = _t4177
                                                                                else:
                                                                                  _t4176 = 0.0
                                                                                _t4173 = _t4176
                                                                              _t4170 = _t4173
                                                                            _t4167 = _t4170
                                                                          _t4163 = _t4167
                                                                        _t4160 = _t4163
                                                                      _t4157 = _t4160
                                                                    _t4155 = _t4157
                                                                  _t4153 = _t4155
                                                                _t4151 = _t4153
                                                              _t4148 = _t4151
                                                            _t4146 = _t4148
                                                          _t4144 = _t4146
                                                        _t4142 = _t4144
                                                      _t4140 = _t4142
                                                    _t4130 = _t4140
                                                  _t4128 = _t4130
                                                _t4119 = _t4128
                                              _t4111 = _t4119
                                            _t4110 = _t4111
                                          _t4107 = _t4110
                                        _t4104 = _t4107
                                      _t4102 = _t4104
                                    _t4100 = _t4102
                                  _t4098 = _t4100
                                _t4096 = _t4098
                              _t4094 = _t4096
                            _t4092 = _t4094
                          _t4090 = _t4092
                        _t4089 = _t4090
                      _t4086 = _t4089
                    _t4083 = _t4086
                  _t4082 = _t4083
                _t4081 = _t4082
              _t4078 = _t4081
            _t4076 = _t4078
          _t4071 = _t4076
        _t4061 = _t4071
      _t4178 = _ix((v_gmem_base + 48.0))
      _t4179 = 0.0
      _gset(_t4178, _t4179)
      _t4180 = _ix((v_gmem_base + 49.0))
      _t4181 = 0.0
      _gset(_t4180, _t4181)
      _t4052 = _t4181
    else:
      _t4052 = 0.0
    v_edit_cmd = _gget((v_gmem_base + 160.0))
    if _tr((1.0 if v_edit_cmd > 0.0 else 0.0)):
      if _tr((0.0 if abs(v_p - (v_active_part - 1.0)) < 0.00001 else 1.0)):
        _t4184 = (v_p + 1.0)
        _t4185 = f_switch_part(_t4184)
        _t4183 = _t4185
      else:
        _t4183 = 0.0
      if _tr((1.0 if v_length > 0.0 else 0.0)):
        _t4187 = 1.0 if _tr(v_br_on) else 0.0
        if _t4187:
          _t4187 = 1.0 if _tr((1.0 if abs(v_edit_cmd - 1.0) < 0.00001 else 0.0)) else 0.0
        if _tr(_t4187):
          v_edit_cmd = 5.0
          _t4188 = v_edit_cmd
        else:
          _t4188 = 0.0
        _t4189 = 1.0 if _tr(v_br_on) else 0.0
        if _t4189:
          _t4190 = 1.0 if _tr((1.0 if abs(v_edit_cmd - 2.0) < 0.00001 else 0.0)) else 0.0
          if not _t4190:
            _t4190 = 1.0 if _tr((1.0 if abs(v_edit_cmd - 3.0) < 0.00001 else 0.0)) else 0.0
          _t4189 = 1.0 if _tr(_t4190) else 0.0
        if _tr(_t4189):
          if _tr((1.0 if abs(v_edit_cmd - 2.0) < 0.00001 else 0.0)):
            _t4192 = (_gget((v_gmem_base + 162.0)) - v_loop_start)
          else:
            _t4192 = _gget((v_gmem_base + 162.0))
          _t4193 = _t4192
          _t4194 = f_br_set_width(_t4193)
          _t4191 = _t4194
        else:
          if _tr((1.0 if abs(v_edit_cmd - 1.0) < 0.00001 else 0.0)):
            v_new_in = _gget((v_gmem_base + 161.0))
            _t4196 = v_new_in
            _t4198 = v_length
            _t4197 = f_min_width()
            _t4199 = (_t4198 - _t4197)
            _t4200 = min(_t4196, _t4199)
            _t4201 = _t4200
            _t4202 = max(0.0, _t4201)
            _t4203 = _t4202
            _t4204 = f_apply_quant_start(_t4203)
            v_new_in = _t4204
            v_old_end = (v_loop_start + v_loop_width)
            v_loop_start = v_new_in
            _t4205 = f_min_width()
            _t4206 = _t4205
            _t4207 = (v_old_end - v_loop_start)
            _t4208 = max(_t4206, _t4207)
            v_loop_width = _t4208
            _t4209 = v_loop_width
            _t4210 = (v_length - v_loop_start)
            _t4211 = min(_t4209, _t4210)
            v_loop_width = _t4211
            v_sync_hard_resync = 1.0
            _t4195 = v_sync_hard_resync
          else:
            if _tr((1.0 if abs(v_edit_cmd - 5.0) < 0.00001 else 0.0)):
              v_new_in = _gget((v_gmem_base + 161.0))
              _t4213 = f_min_width()
              _t4214 = _t4213
              _t4215 = v_loop_width
              _t4216 = max(_t4214, _t4215)
              v_keep_w = _t4216
              _t4217 = v_new_in
              _t4219 = v_length
              _t4218 = f_min_width()
              _t4220 = (_t4219 - _t4218)
              _t4221 = min(_t4217, _t4220)
              _t4222 = _t4221
              _t4223 = max(0.0, _t4222)
              _t4224 = _t4223
              _t4225 = f_apply_quant_start(_t4224)
              v_new_in = _t4225
              _t4226 = v_new_in
              _t4227 = (v_length - v_keep_w)
              _t4228 = min(_t4226, _t4227)
              _t4229 = _t4228
              _t4230 = max(0.0, _t4229)
              v_new_in = _t4230
              v_loop_start = v_new_in
              v_loop_width = v_keep_w
              v_sync_hard_resync = 1.0
              _t4212 = v_sync_hard_resync
            else:
              if _tr((1.0 if abs(v_edit_cmd - 2.0) < 0.00001 else 0.0)):
                v_new_out = _gget((v_gmem_base + 162.0))
                _t4232 = f_quant_grid()
                v_gq = _t4232
                if _tr((1.0 if v_gq > 0.0 else 0.0)):
                  _t4234 = (_div(v_new_out, v_gq) + 0.5)
                  _t4235 = _floor(_t4234)
                  v_new_out = (_t4235 * v_gq)
                  _t4233 = v_new_out
                else:
                  _t4233 = 0.0
                _t4237 = v_loop_start
                _t4236 = f_min_width()
                _t4238 = (_t4237 + _t4236)
                _t4239 = v_new_out
                _t4240 = v_length
                _t4241 = min(_t4239, _t4240)
                _t4242 = _t4241
                _t4243 = max(_t4238, _t4242)
                v_new_out = _t4243
                v_loop_width = (v_new_out - v_loop_start)
                v_sync_hard_resync = 1.0
                _t4231 = v_sync_hard_resync
              else:
                if _tr((1.0 if abs(v_edit_cmd - 3.0) < 0.00001 else 0.0)):
                  v_new_w = _gget((v_gmem_base + 162.0))
                  _t4245 = v_new_w
                  _t4246 = v_loop_start
                  _t4247 = f_apply_quant_width(_t4245, _t4246)
                  v_loop_width = _t4247
                  v_sync_hard_resync = 1.0
                  _t4244 = v_sync_hard_resync
                else:
                  if _tr((1.0 if abs(v_edit_cmd - 4.0) < 0.00001 else 0.0)):
                    v_loop_start = 0.0
                    v_loop_width = v_length
                    v_sync_hard_resync = 1.0
                    _t4248 = v_sync_hard_resync
                  else:
                    _t4248 = 0.0
                  _t4244 = _t4248
                _t4231 = _t4244
              _t4212 = _t4231
            _t4195 = _t4212
          _t4191 = _t4195
        _t4186 = _t4191
      else:
        _t4186 = 0.0
      _t4249 = _ix((v_gmem_base + 160.0))
      _t4250 = 0.0
      _gset(_t4249, _t4250)
      _t4251 = _ix((v_gmem_base + 161.0))
      _t4252 = 0.0
      _gset(_t4251, _t4252)
      _t4253 = _ix((v_gmem_base + 162.0))
      _t4254 = 0.0
      _gset(_t4253, _t4254)
      _t4182 = _t4254
    else:
      _t4182 = 0.0
    v_wr_mb = 0.0
    for _t4255 in range(max(0, int(3.0))):
      if _tr((1.0 if abs(v_wr_mb - 0.0) < 0.00001 else 0.0)):
        _t4256 = 180.0
      else:
        if _tr((1.0 if abs(v_wr_mb - 1.0) < 0.00001 else 0.0)):
          _t4257 = 195.0
        else:
          _t4257 = 197.0
        _t4256 = _t4257
      v_wr_mo = _t4256
      v_wr_id = _gget((v_gmem_base + v_wr_mo))
      if _tr((1.0 if v_wr_id > 0.0 else 0.0)):
        if _tr((0.0 if abs(v_p - (v_active_part - 1.0)) < 0.00001 else 1.0)):
          _t4260 = (v_p + 1.0)
          _t4261 = f_switch_part(_t4260)
          _t4259 = _t4261
        else:
          _t4259 = 0.0
        v_wr_v = _gget(((v_gmem_base + v_wr_mo) + 1.0))
        if _tr((1.0 if abs(v_wr_id - 3.0) < 0.00001 else 0.0)):
          _t4263 = v_wr_v
          _t4264 = min(100.0, _t4263)
          _t4265 = _t4264
          _t4266 = max(0.01, _t4265)
          v_speed = _t4266
          v_speed = v_speed
          _t4262 = v_speed
        else:
          if _tr((1.0 if abs(v_wr_id - 4.0) < 0.00001 else 0.0)):
            _t4268 = (-48.0)
            _t4269 = v_wr_v
            _t4270 = min(48.0, _t4269)
            _t4271 = _t4270
            _t4272 = max(_t4268, _t4271)
            v_pitch = _t4272
            v_pitch = v_pitch
            _t4267 = v_pitch
          else:
            if _tr((1.0 if abs(v_wr_id - 5.0) < 0.00001 else 0.0)):
              _t4274 = v_wr_v
              _t4275 = min(1.0, _t4274)
              _t4276 = _t4275
              _t4277 = max(0.0, _t4276)
              v_mix = _t4277
              v_mix = v_mix
              _t4273 = v_mix
            else:
              if _tr((1.0 if abs(v_wr_id - 6.0) < 0.00001 else 0.0)):
                _t4279 = v_wr_v
                _t4280 = min(200.0, _t4279)
                _t4281 = _t4280
                _t4282 = max(20.0, _t4281)
                v_grain_ms = _t4282
                v_grain_ms = v_grain_ms
                _t4278 = v_grain_ms
              else:
                if _tr((1.0 if abs(v_wr_id - 7.0) < 0.00001 else 0.0)):
                  _t4284 = v_wr_v
                  _t4285 = min(500.0, _t4284)
                  _t4286 = _t4285
                  _t4287 = max(0.0, _t4286)
                  v_fade_ms = _t4287
                  v_fade_ms = v_fade_ms
                  _t4283 = v_fade_ms
                else:
                  if _tr((1.0 if abs(v_wr_id - 10.0) < 0.00001 else 0.0)):
                    if _tr((1.0 if v_length > 0.0 else 0.0)):
                      _t4290 = v_wr_v
                      _t4291 = min(100.0, _t4290)
                      _t4292 = _t4291
                      _t4293 = max(0.0, _t4292)
                      v_req_p = ((_t4293 * 0.01) * v_length)
                      _t4294 = v_req_p
                      _t4295 = f_trigger_pos_jump(_t4294)
                      v_loop_pos_pct = (_div(v_pos, v_length) * 100.0)
                      v_last_slider9 = v_loop_pos_pct
                      _t4289 = v_last_slider9
                    else:
                      _t4289 = 0.0
                    _t4288 = _t4289
                  else:
                    if _tr((1.0 if abs(v_wr_id - 13.0) < 0.00001 else 0.0)):
                      _t4297 = v_wr_v
                      _t4298 = min(50.0, _t4297)
                      _t4299 = _t4298
                      _t4300 = max(5.0, _t4299)
                      v_grain_fade = _t4300
                      v_grain_fade = v_grain_fade
                      _t4296 = v_grain_fade
                    else:
                      if _tr((1.0 if abs(v_wr_id - 19.0) < 0.00001 else 0.0)):
                        _t4302 = v_wr_v
                        _t4303 = min(2.0, _t4302)
                        _t4304 = _t4303
                        _t4305 = max(0.0, _t4304)
                        v_feedback = _t4305
                        v_feedback = v_feedback
                        _t4301 = v_feedback
                      else:
                        if _tr((1.0 if abs(v_wr_id - 20.0) < 0.00001 else 0.0)):
                          _t4307 = v_wr_v
                          _t4308 = min(1.0, _t4307)
                          _t4309 = _t4308
                          _t4310 = max(0.0, _t4309)
                          v_degradation = _t4310
                          v_degradation = v_degradation
                          _t4306 = v_degradation
                        else:
                          if _tr((1.0 if abs(v_wr_id - 21.0) < 0.00001 else 0.0)):
                            _t4312 = v_wr_v
                            _t4313 = min(1.0, _t4312)
                            _t4314 = _t4313
                            _t4315 = max(0.0, _t4314)
                            v_stereo_width = _t4315
                            v_stereo_width = v_stereo_width
                            _t4311 = v_stereo_width
                          else:
                            if _tr((1.0 if abs(v_wr_id - 22.0) < 0.00001 else 0.0)):
                              _t4317 = v_wr_v
                              _t4318 = min(2.0, _t4317)
                              _t4319 = _t4318
                              _t4320 = max(0.0, _t4319)
                              v_out_vol = _t4320
                              v_out_vol = v_out_vol
                              _t4316 = v_out_vol
                            else:
                              if _tr((1.0 if abs(v_wr_id - 26.0) < 0.00001 else 0.0)):
                                _t4322 = v_wr_v
                                _t4323 = min(1.0, _t4322)
                                _t4324 = _t4323
                                _t4325 = max(0.0, _t4324)
                                v_cloud_density = _t4325
                                v_cloud_density = v_cloud_density
                                _t4321 = v_cloud_density
                              else:
                                if _tr((1.0 if abs(v_wr_id - 27.0) < 0.00001 else 0.0)):
                                  _t4327 = v_wr_v
                                  _t4328 = min(1.0, _t4327)
                                  _t4329 = _t4328
                                  _t4330 = max(0.0, _t4329)
                                  v_cloud_chaos = _t4330
                                  v_cloud_chaos = v_cloud_chaos
                                  _t4326 = v_cloud_chaos
                                else:
                                  if _tr((1.0 if abs(v_wr_id - 28.0) < 0.00001 else 0.0)):
                                    _t4332 = v_wr_v
                                    _t4333 = min(1.0, _t4332)
                                    _t4334 = _t4333
                                    _t4335 = max(0.0, _t4334)
                                    v_cloud_spread = _t4335
                                    v_cloud_spread = v_cloud_spread
                                    _t4331 = v_cloud_spread
                                  else:
                                    if _tr((1.0 if abs(v_wr_id - 29.0) < 0.00001 else 0.0)):
                                      _t4337 = v_wr_v
                                      _t4338 = min(100.0, _t4337)
                                      _t4339 = _t4338
                                      _t4340 = max(0.0, _t4339)
                                      v_dens_occ = _t4340
                                      v_dens_occ = v_dens_occ
                                      _t4336 = v_dens_occ
                                    else:
                                      if _tr((1.0 if abs(v_wr_id - 30.0) < 0.00001 else 0.0)):
                                        _t4342 = (v_wr_v + 0.5)
                                        _t4343 = _floor(_t4342)
                                        _t4344 = _t4343
                                        _t4345 = min(6.0, _t4344)
                                        _t4346 = _t4345
                                        _t4347 = max(0.0, _t4346)
                                        v_dens_len = _t4347
                                        v_dens_len = v_dens_len
                                        _t4341 = v_dens_len
                                      else:
                                        if _tr((1.0 if abs(v_wr_id - 34.0) < 0.00001 else 0.0)):
                                          _t4349 = v_wr_v
                                          _t4350 = min(100.0, _t4349)
                                          _t4351 = _t4350
                                          _t4352 = max(0.0, _t4351)
                                          v_slicer_pitch_spread = _t4352
                                          v_slicer_pitch_spread = v_slicer_pitch_spread
                                          _t4348 = v_slicer_pitch_spread
                                        else:
                                          if _tr((1.0 if abs(v_wr_id - 35.0) < 0.00001 else 0.0)):
                                            _t4354 = v_wr_v
                                            _t4355 = min(100.0, _t4354)
                                            _t4356 = _t4355
                                            _t4357 = max(0.0, _t4356)
                                            v_cloud_pitch_spread = _t4357
                                            v_cloud_pitch_spread = v_cloud_pitch_spread
                                            _t4353 = v_cloud_pitch_spread
                                          else:
                                            if _tr((1.0 if abs(v_wr_id - 36.0) < 0.00001 else 0.0)):
                                              _t4359 = v_wr_v
                                              _t4360 = min(1.0, _t4359)
                                              _t4361 = _t4360
                                              _t4362 = max(0.0, _t4361)
                                              v_cloud_mix = _t4362
                                              v_cloud_mix = v_cloud_mix
                                              _t4358 = v_cloud_mix
                                            else:
                                              if _tr((1.0 if abs(v_wr_id - 38.0) < 0.00001 else 0.0)):
                                                _t4364 = v_wr_v
                                                _t4365 = min(100.0, _t4364)
                                                _t4366 = _t4365
                                                _t4367 = max(0.0, _t4366)
                                                v_cloud_pos_pct = _t4367
                                                v_cloud_pos_pct = v_cloud_pos_pct
                                                _t4363 = v_cloud_pos_pct
                                              else:
                                                if _tr((1.0 if abs(v_wr_id - 40.0) < 0.00001 else 0.0)):
                                                  _t4369 = v_wr_v
                                                  _t4370 = min(4.0, _t4369)
                                                  _t4371 = _t4370
                                                  _t4372 = max(0.1, _t4371)
                                                  v_cloud_lfo_rate = _t4372
                                                  v_cloud_lfo_rate = v_cloud_lfo_rate
                                                  _t4368 = v_cloud_lfo_rate
                                                else:
                                                  if _tr((1.0 if abs(v_wr_id - 41.0) < 0.00001 else 0.0)):
                                                    _t4374 = v_wr_v
                                                    _t4375 = min(100.0, _t4374)
                                                    _t4376 = _t4375
                                                    _t4377 = max(0.0, _t4376)
                                                    v_cloud_lfo_depth = _t4377
                                                    v_cloud_lfo_depth = v_cloud_lfo_depth
                                                    _t4373 = v_cloud_lfo_depth
                                                  else:
                                                    if _tr((1.0 if abs(v_wr_id - 11.0) < 0.00001 else 0.0)):
                                                      _t4379 = v_wr_v
                                                      _t4380 = min(0.8, _t4379)
                                                      _t4381 = _t4380
                                                      _t4382 = max(0.01, _t4381)
                                                      v_trans_sens = _t4382
                                                      v_trans_sens = v_trans_sens
                                                      _t4378 = v_trans_sens
                                                    else:
                                                      if _tr((1.0 if abs(v_wr_id - 12.0) < 0.00001 else 0.0)):
                                                        _t4384 = v_wr_v
                                                        _t4385 = min(1000.0, _t4384)
                                                        _t4386 = _t4385
                                                        _t4387 = max(30.0, _t4386)
                                                        v_trans_hold_ms = _t4387
                                                        v_trans_hold_ms = v_trans_hold_ms
                                                        _t4383 = v_trans_hold_ms
                                                      else:
                                                        if _tr((1.0 if abs(v_wr_id - 14.0) < 0.00001 else 0.0)):
                                                          _t4389 = (v_wr_v + 0.5)
                                                          _t4390 = _floor(_t4389)
                                                          _t4391 = _t4390
                                                          _t4392 = min(5.0, _t4391)
                                                          _t4393 = _t4392
                                                          _t4394 = max(0.0, _t4393)
                                                          v_slicer_mode = _t4394
                                                          v_slicer_mode = v_slicer_mode
                                                          _t4395 = f_slicer_regen()
                                                          _t4388 = _t4395
                                                        else:
                                                          if _tr((1.0 if abs(v_wr_id - 15.0) < 0.00001 else 0.0)):
                                                            _t4397 = (v_wr_v + 0.5)
                                                            _t4398 = _floor(_t4397)
                                                            _t4399 = _t4398
                                                            _t4400 = min(5.0, _t4399)
                                                            _t4401 = _t4400
                                                            _t4402 = max(0.0, _t4401)
                                                            v_slicer_sub = _t4402
                                                            v_slicer_sub = v_slicer_sub
                                                            _t4396 = v_slicer_sub
                                                          else:
                                                            if _tr((1.0 if abs(v_wr_id - 16.0) < 0.00001 else 0.0)):
                                                              _t4404 = v_wr_v
                                                              _t4405 = min(2000.0, _t4404)
                                                              _t4406 = _t4405
                                                              _t4407 = max(4.0, _t4406)
                                                              v_slice_decay_ms = _t4407
                                                              _t4408 = v_slice_decay_ms
                                                              _t4409 = f_decay_ms_to_pos(_t4408)
                                                              v_slice_decay_pos = _t4409
                                                              v_slice_decay_pos = v_slice_decay_pos
                                                              _t4403 = v_slice_decay_pos
                                                            else:
                                                              if _tr((1.0 if abs(v_wr_id - 32.0) < 0.00001 else 0.0)):
                                                                if _tr((1.0 if v_wr_v >= 0.5 else 0.0)):
                                                                  _t4411 = 1.0
                                                                else:
                                                                  _t4411 = 0.0
                                                                v_slicer_src = _t4411
                                                                v_slicer_src = v_slicer_src
                                                                v_src_auto = 0.0
                                                                v_src_auto = 0.0
                                                                _t4410 = v_src_auto
                                                              else:
                                                                if _tr((1.0 if abs(v_wr_id - 57.0) < 0.00001 else 0.0)):
                                                                  if _tr((1.0 if v_wr_v >= 0.5 else 0.0)):
                                                                    _t4413 = 1.0
                                                                  else:
                                                                    _t4413 = 0.0
                                                                  v_src_auto = _t4413
                                                                  v_src_auto = v_src_auto
                                                                  if _tr(v_src_auto):
                                                                    _t4415 = f_start_analysis_ex(1.0)
                                                                    _t4414 = _t4415
                                                                  else:
                                                                    _t4414 = 0.0
                                                                  _t4412 = _t4414
                                                                else:
                                                                  if _tr((1.0 if abs(v_wr_id - 33.0) < 0.00001 else 0.0)):
                                                                    _t4417 = (v_wr_v + 0.5)
                                                                    _t4418 = _floor(_t4417)
                                                                    _t4419 = _t4418
                                                                    _t4420 = min(9.0, _t4419)
                                                                    _t4421 = _t4420
                                                                    _t4422 = max(0.0, _t4421)
                                                                    v_grid_sub = _t4422
                                                                    v_grid_sub = v_grid_sub
                                                                    _t4416 = v_grid_sub
                                                                  else:
                                                                    if _tr((1.0 if abs(v_wr_id - 37.0) < 0.00001 else 0.0)):
                                                                      if _tr((1.0 if v_wr_v >= 0.5 else 0.0)):
                                                                        _t4424 = 1.0
                                                                      else:
                                                                        _t4424 = 0.0
                                                                      v_cloud_pos_mode = _t4424
                                                                      v_cloud_pos_mode = v_cloud_pos_mode
                                                                      _t4423 = v_cloud_pos_mode
                                                                    else:
                                                                      if _tr((1.0 if abs(v_wr_id - 39.0) < 0.00001 else 0.0)):
                                                                        _t4426 = (v_wr_v + 0.5)
                                                                        _t4427 = _floor(_t4426)
                                                                        _t4428 = _t4427
                                                                        _t4429 = min(2.0, _t4428)
                                                                        _t4430 = _t4429
                                                                        _t4431 = max(0.0, _t4430)
                                                                        v_cloud_lfo_shape = _t4431
                                                                        v_cloud_lfo_shape = v_cloud_lfo_shape
                                                                        _t4425 = v_cloud_lfo_shape
                                                                      else:
                                                                        if _tr((1.0 if abs(v_wr_id - 42.0) < 0.00001 else 0.0)):
                                                                          _t4433 = (v_wr_v + 0.5)
                                                                          _t4434 = _floor(_t4433)
                                                                          _t4435 = _t4434
                                                                          _t4436 = min(127.0, _t4435)
                                                                          _t4437 = _t4436
                                                                          _t4438 = max(0.0, _t4437)
                                                                          v_sampler_root = _t4438
                                                                          v_sampler_root = v_sampler_root
                                                                          _t4432 = v_sampler_root
                                                                        else:
                                                                          if _tr((1.0 if abs(v_wr_id - 43.0) < 0.00001 else 0.0)):
                                                                            if _tr((1.0 if v_wr_v >= 0.5 else 0.0)):
                                                                              _t4440 = 1.0
                                                                            else:
                                                                              _t4440 = 0.0
                                                                            v_sampler_pitch_mode = _t4440
                                                                            v_sampler_pitch_mode = v_sampler_pitch_mode
                                                                            _t4439 = v_sampler_pitch_mode
                                                                          else:
                                                                            if _tr((1.0 if abs(v_wr_id - 44.0) < 0.00001 else 0.0)):
                                                                              _t4442 = v_wr_v
                                                                              _t4443 = min(3000.0, _t4442)
                                                                              _t4444 = _t4443
                                                                              _t4445 = max(0.0, _t4444)
                                                                              v_sampler_release = _t4445
                                                                              v_sampler_release = v_sampler_release
                                                                              _t4441 = v_sampler_release
                                                                            else:
                                                                              if _tr((1.0 if abs(v_wr_id - 47.0) < 0.00001 else 0.0)):
                                                                                _t4447 = (v_wr_v + 0.5)
                                                                                _t4448 = _floor(_t4447)
                                                                                _t4449 = _t4448
                                                                                _t4450 = min(32.0, _t4449)
                                                                                _t4451 = _t4450
                                                                                _t4452 = max(1.0, _t4451)
                                                                                v_slicer_steps = _t4452
                                                                                v_slicer_steps = v_slicer_steps
                                                                                _t4446 = v_slicer_steps
                                                                              else:
                                                                                if _tr((1.0 if abs(v_wr_id - 48.0) < 0.00001 else 0.0)):
                                                                                  _t4454 = (v_wr_v + 0.5)
                                                                                  _t4455 = _floor(_t4454)
                                                                                  _t4456 = _t4455
                                                                                  _t4457 = min(32.0, _t4456)
                                                                                  _t4458 = _t4457
                                                                                  _t4459 = max(0.0, _t4458)
                                                                                  v_max_slices = _t4459
                                                                                  v_max_slices = v_max_slices
                                                                                  _t4453 = v_max_slices
                                                                                else:
                                                                                  if _tr((1.0 if abs(v_wr_id - 49.0) < 0.00001 else 0.0)):
                                                                                    _t4461 = (v_wr_v + 0.5)
                                                                                    _t4462 = _floor(_t4461)
                                                                                    _t4463 = _t4462
                                                                                    _t4464 = min(4.0, _t4463)
                                                                                    _t4465 = _t4464
                                                                                    _t4466 = max(1.0, _t4465)
                                                                                    v_slicer_preset = _t4466
                                                                                    v_slicer_preset = v_slicer_preset
                                                                                    _t4460 = v_slicer_preset
                                                                                  else:
                                                                                    if _tr((1.0 if abs(v_wr_id - 50.0) < 0.00001 else 0.0)):
                                                                                      _t4468 = v_wr_v
                                                                                      _t4469 = min(0.8, _t4468)
                                                                                      _t4470 = _t4469
                                                                                      _t4471 = max(0.001, _t4470)
                                                                                      v_det_thresh = _t4471
                                                                                      v_det_thresh = v_det_thresh
                                                                                      _t4467 = v_det_thresh
                                                                                    else:
                                                                                      if _tr((1.0 if abs(v_wr_id - 55.0) < 0.00001 else 0.0)):
                                                                                        _t4473 = (v_wr_v + 0.5)
                                                                                        _t4474 = _floor(_t4473)
                                                                                        _t4475 = _t4474
                                                                                        _t4476 = min(100.0, _t4475)
                                                                                        _t4477 = _t4476
                                                                                        _t4478 = max(0.0, _t4477)
                                                                                        v_slice_attack_ms = _t4478
                                                                                        v_slice_attack_ms = v_slice_attack_ms
                                                                                        _t4472 = v_slice_attack_ms
                                                                                      else:
                                                                                        if _tr((1.0 if abs(v_wr_id - 58.0) < 0.00001 else 0.0)):
                                                                                          if _tr((1.0 if v_wr_v >= 0.5 else 0.0)):
                                                                                            _t4480 = 1.0
                                                                                          else:
                                                                                            _t4480 = 0.0
                                                                                          v_slicer_link = _t4480
                                                                                          v_slicer_link = v_slicer_link
                                                                                          _t4479 = v_slicer_link
                                                                                        else:
                                                                                          if _tr((1.0 if abs(v_wr_id - 56.0) < 0.00001 else 0.0)):
                                                                                            _t4482 = f_slicer_regen()
                                                                                            _t4481 = _t4482
                                                                                          else:
                                                                                            if _tr((1.0 if abs(v_wr_id - 61.0) < 0.00001 else 0.0)):
                                                                                              _t4484 = v_wr_v
                                                                                              _t4485 = min(1.0, _t4484)
                                                                                              _t4486 = _t4485
                                                                                              _t4487 = max(0.0, _t4486)
                                                                                              v_slx_mix = _t4487
                                                                                              v_slx_mix = v_slx_mix
                                                                                              _t4483 = v_slx_mix
                                                                                            else:
                                                                                              if _tr((1.0 if abs(v_wr_id - 60.0) < 0.00001 else 0.0)):
                                                                                                _t4489 = v_wr_v
                                                                                                _t4490 = min(1.0, _t4489)
                                                                                                _t4491 = _t4490
                                                                                                _t4492 = max(0.0, _t4491)
                                                                                                v_br_mix = _t4492
                                                                                                v_br_mix = v_br_mix
                                                                                                _t4488 = v_br_mix
                                                                                              else:
                                                                                                if _tr((1.0 if abs(v_wr_id - 59.0) < 0.00001 else 0.0)):
                                                                                                  _t4494 = (v_wr_v + 0.5)
                                                                                                  _t4495 = _floor(_t4494)
                                                                                                  _t4496 = _t4495
                                                                                                  _t4497 = min(9.0, _t4496)
                                                                                                  _t4498 = _t4497
                                                                                                  _t4499 = max(0.0, _t4498)
                                                                                                  v_loop_quant = _t4499
                                                                                                  v_loop_quant = v_loop_quant
                                                                                                  if _tr(v_br_on):
                                                                                                    _t4501 = f_br_refresh()
                                                                                                    _t4500 = _t4501
                                                                                                  else:
                                                                                                    if _tr((1.0 if v_length > 0.0 else 0.0)):
                                                                                                      _t4503 = v_loop_start
                                                                                                      _t4504 = f_apply_quant_start(_t4503)
                                                                                                      v_loop_start = _t4504
                                                                                                      _t4505 = v_loop_width
                                                                                                      _t4506 = v_loop_start
                                                                                                      _t4507 = f_apply_quant_width(_t4505, _t4506)
                                                                                                      v_loop_width = _t4507
                                                                                                      v_sync_hard_resync = 1.0
                                                                                                      _t4502 = v_sync_hard_resync
                                                                                                    else:
                                                                                                      _t4502 = 0.0
                                                                                                    _t4500 = _t4502
                                                                                                  _t4493 = _t4500
                                                                                                else:
                                                                                                  if _tr((1.0 if abs(v_wr_id - 51.0) < 0.00001 else 0.0)):
                                                                                                    _t4509 = v_wr_v
                                                                                                    _t4510 = min(1000.0, _t4509)
                                                                                                    _t4511 = _t4510
                                                                                                    _t4512 = max(30.0, _t4511)
                                                                                                    v_det_hold_ms = _t4512
                                                                                                    v_det_hold_ms = v_det_hold_ms
                                                                                                    _t4508 = v_det_hold_ms
                                                                                                  else:
                                                                                                    if _tr((1.0 if abs(v_wr_id - 62.0) < 0.00001 else 0.0)):
                                                                                                      _t4514 = v_wr_v
                                                                                                      _t4515 = min(1000.0, _t4514)
                                                                                                      _t4516 = _t4515
                                                                                                      _t4517 = max(1.0, _t4516)
                                                                                                      v_cloud_size = _t4517
                                                                                                      v_cloud_size = v_cloud_size
                                                                                                      _t4513 = v_cloud_size
                                                                                                    else:
                                                                                                      if _tr((1.0 if abs(v_wr_id - 63.0) < 0.00001 else 0.0)):
                                                                                                        if _tr((1.0 if v_wr_v >= 0.5 else 0.0)):
                                                                                                          _t4519 = 1.0
                                                                                                        else:
                                                                                                          _t4519 = 0.0
                                                                                                        v_cloud_freeze = _t4519
                                                                                                        v_cloud_freeze = v_cloud_freeze
                                                                                                        _t4518 = v_cloud_freeze
                                                                                                      else:
                                                                                                        if _tr((1.0 if abs(v_wr_id - 64.0) < 0.00001 else 0.0)):
                                                                                                          _t4521 = v_wr_v
                                                                                                          _t4522 = min(1.0, _t4521)
                                                                                                          _t4523 = _t4522
                                                                                                          _t4524 = max(0.0, _t4523)
                                                                                                          v_cloud_diffuse = _t4524
                                                                                                          v_cloud_diffuse = v_cloud_diffuse
                                                                                                          _t4520 = v_cloud_diffuse
                                                                                                        else:
                                                                                                          if _tr((1.0 if abs(v_wr_id - 65.0) < 0.00001 else 0.0)):
                                                                                                            _t4526 = (v_wr_v + 0.5)
                                                                                                            _t4527 = _floor(_t4526)
                                                                                                            _t4528 = _t4527
                                                                                                            _t4529 = min(5.0, _t4528)
                                                                                                            _t4530 = _t4529
                                                                                                            _t4531 = max(0.0, _t4530)
                                                                                                            v_warp_grid = _t4531
                                                                                                            v_warp_grid = v_warp_grid
                                                                                                            _t4525 = v_warp_grid
                                                                                                          else:
                                                                                                            if _tr((1.0 if abs(v_wr_id - 66.0) < 0.00001 else 0.0)):
                                                                                                              _t4533 = v_wr_v
                                                                                                              _t4534 = min(100.0, _t4533)
                                                                                                              _t4535 = _t4534
                                                                                                              _t4536 = max(0.0, _t4535)
                                                                                                              v_warp_force = _t4536
                                                                                                              v_warp_force = v_warp_force
                                                                                                              _t4532 = v_warp_force
                                                                                                            else:
                                                                                                              _t4532 = 0.0
                                                                                                            _t4525 = _t4532
                                                                                                          _t4520 = _t4525
                                                                                                        _t4518 = _t4520
                                                                                                      _t4513 = _t4518
                                                                                                    _t4508 = _t4513
                                                                                                  _t4493 = _t4508
                                                                                                _t4488 = _t4493
                                                                                              _t4483 = _t4488
                                                                                            _t4481 = _t4483
                                                                                          _t4479 = _t4481
                                                                                        _t4472 = _t4479
                                                                                      _t4467 = _t4472
                                                                                    _t4460 = _t4467
                                                                                  _t4453 = _t4460
                                                                                _t4446 = _t4453
                                                                              _t4441 = _t4446
                                                                            _t4439 = _t4441
                                                                          _t4432 = _t4439
                                                                        _t4425 = _t4432
                                                                      _t4423 = _t4425
                                                                    _t4416 = _t4423
                                                                  _t4412 = _t4416
                                                                _t4410 = _t4412
                                                              _t4403 = _t4410
                                                            _t4396 = _t4403
                                                          _t4388 = _t4396
                                                        _t4383 = _t4388
                                                      _t4378 = _t4383
                                                    _t4373 = _t4378
                                                  _t4368 = _t4373
                                                _t4363 = _t4368
                                              _t4358 = _t4363
                                            _t4353 = _t4358
                                          _t4348 = _t4353
                                        _t4341 = _t4348
                                      _t4336 = _t4341
                                    _t4331 = _t4336
                                  _t4326 = _t4331
                                _t4321 = _t4326
                              _t4316 = _t4321
                            _t4311 = _t4316
                          _t4306 = _t4311
                        _t4301 = _t4306
                      _t4296 = _t4301
                    _t4288 = _t4296
                  _t4283 = _t4288
                _t4278 = _t4283
              _t4273 = _t4278
            _t4267 = _t4273
          _t4262 = _t4267
        _t4537 = _ix((v_gmem_base + v_wr_mo))
        _t4538 = 0.0
        _gset(_t4537, _t4538)
        _t4539 = _ix(((v_gmem_base + v_wr_mo) + 1.0))
        _t4540 = 0.0
        _gset(_t4539, _t4540)
        _t4258 = _t4540
      else:
        _t4258 = 0.0
      v_wr_mb = (v_wr_mb + 1.0)
    _t4541 = _ix((v_gmem_base + 199.0))
    _t4542 = v_lp_mute
    _gset(_t4541, _t4542)
    _t4543 = _ix((v_gmem_base + 156.0))
    _t4544 = v_wp_pub
    _gset(_t4543, _t4544)
    _t4545 = _ix((v_gmem_base + 157.0))
    _t4546 = v_warp_grid
    _gset(_t4545, _t4546)
    _t4547 = _ix((v_gmem_base + 158.0))
    _t4548 = v_warp_force
    _gset(_t4547, _t4548)
    _t4549 = _ix((v_gmem_base + 0.0))
    _t4550 = v_instance_id
    _gset(_t4549, _t4550)
    _t4551 = _ix((v_gmem_base + 1.0))
    _t4552 = v_instance_alias
    _gset(_t4551, _t4552)
    if _tr((1.0 if abs(v_p - (v_active_part - 1.0)) < 0.00001 else 0.0)):
      _t4553 = v_length
    else:
      if _tr((1.0 if abs(v_p - 0.0) < 0.00001 else 0.0)):
        _t4554 = v_len_part1
      else:
        if _tr((1.0 if abs(v_p - 1.0) < 0.00001 else 0.0)):
          _t4555 = v_len_part2
        else:
          _t4555 = v_len_part3
        _t4554 = _t4555
      _t4553 = _t4554
    v_sy_plen = _t4553
    if _tr((1.0 if abs(v_p - (v_active_part - 1.0)) < 0.00001 else 0.0)):
      _t4556 = v_base_loop_length
    else:
      if _tr((1.0 if abs(v_p - 0.0) < 0.00001 else 0.0)):
        _t4557 = v_base_len_part1
      else:
        if _tr((1.0 if abs(v_p - 1.0) < 0.00001 else 0.0)):
          _t4558 = v_base_len_part2
        else:
          _t4558 = v_base_len_part3
        _t4557 = _t4558
      _t4556 = _t4557
    v_sy_pbase = _t4556
    _t4560 = 1.0 if _tr((1.0 if v_sy_plen > 0.0 else 0.0)) else 0.0
    if _t4560:
      _t4560 = 1.0 if _tr((1.0 if _mget(v_part_sp + v_p) < 0.0 else 0.0)) else 0.0
    _t4559 = 1.0 if _tr(_t4560) else 0.0
    if _t4559:
      _t4561 = v_p
      _t4562 = f_sy_is_master(_t4561)
      _t4559 = 1.0 if _tr(_t4562) else 0.0
    if _tr(_t4559):
      _t4564 = v_p
      if _tr((1.0 if v_sy_pbase > 0.0 else 0.0)):
        _t4565 = v_sy_pbase
      else:
        _t4565 = v_sy_plen
      _t4566 = _t4565
      _t4567 = f_sy_make_own(_t4564, _t4566)
      _t4563 = _t4567
    else:
      _t4563 = 0.0
    _t4568 = _ix((v_gmem_base + 187.0))
    _t4569 = 1.0 if _tr((1.0 if v_sy_plen > 0.0 else 0.0)) else 0.0
    if _t4569:
      _t4570 = v_p
      _t4571 = f_sy_is_master(_t4570)
      _t4569 = 1.0 if _tr(_t4571) else 0.0
    if _tr(_t4569):
      _t4572 = 1.0
    else:
      _t4572 = 0.0
    _t4573 = _t4572
    _gset(_t4568, _t4573)
    _t4574 = _ix((v_gmem_base + 188.0))
    if _tr((1.0 if abs(v_p - (v_active_part - 1.0)) < 0.00001 else 0.0)):
      _t4575 = v_xarm
    else:
      _t4575 = 0.0
    _t4576 = _t4575
    _gset(_t4574, _t4576)
    _t4577 = _ix((v_gmem_base + 189.0))
    _t4578 = v_br_on
    _gset(_t4577, _t4578)
    _t4579 = _ix((v_gmem_base + 182.0))
    _t4580 = v_p
    _t4581 = v_sy_plen
    _t4582 = f_sy_pos(_t4580, _t4581)
    _t4583 = _t4582
    _gset(_t4579, _t4583)
    _t4584 = _ix((v_gmem_base + 183.0))
    _t4585 = v_p
    _t4586 = v_sy_plen
    _t4587 = f_sy_id(_t4585, _t4586)
    _t4588 = _t4587
    _gset(_t4584, _t4588)
    _t4589 = _ix((v_gmem_base + 184.0))
    _t4590 = v_p
    _t4591 = v_sy_plen
    _t4592 = v_sy_pbase
    _t4593 = f_sy_len(_t4590, _t4591, _t4592)
    _t4594 = _t4593
    _gset(_t4589, _t4594)
    _t4595 = _ix((v_gmem_base + 185.0))
    _t4596 = v_p
    _t4597 = v_sy_plen
    _t4598 = f_sy_live(_t4596, _t4597)
    _t4599 = _t4598
    _gset(_t4595, _t4599)
    _t4600 = _ix((v_gmem_base + 186.0))
    _t4601 = v_srate
    _gset(_t4600, _t4601)
    v_is_active = (1.0 if abs(v_p - (v_active_part - 1.0)) < 0.00001 else 0.0)
    if _tr(v_is_active):
      _t4603 = _ix((v_gmem_base + 2.0))
      _t4604 = v_state
      _gset(_t4603, _t4604)
      _t4605 = _ix((v_gmem_base + 3.0))
      _t4606 = v_speed
      _gset(_t4605, _t4606)
      _t4607 = _ix((v_gmem_base + 4.0))
      _t4608 = v_pitch
      _gset(_t4607, _t4608)
      _t4609 = _ix((v_gmem_base + 5.0))
      _t4610 = v_mix
      _gset(_t4609, _t4610)
      _t4611 = _ix((v_gmem_base + 6.0))
      _t4612 = v_grain_ms
      _gset(_t4611, _t4612)
      _t4613 = _ix((v_gmem_base + 7.0))
      _t4614 = v_fade_ms
      _gset(_t4613, _t4614)
      _t4615 = _ix((v_gmem_base + 8.0))
      _t4616 = v_play_mode
      _gset(_t4615, _t4616)
      _t4617 = _ix((v_gmem_base + 9.0))
      _t4618 = v_link_on
      _gset(_t4617, _t4618)
      _t4619 = _ix((v_gmem_base + 10.0))
      _t4620 = v_loop_pos_pct
      _gset(_t4619, _t4620)
      _t4621 = _ix((v_gmem_base + 47.0))
      if _tr((1.0 if v_length > 0.0 else 0.0)):
        _t4622 = (_div(v_pos, v_length) * 100.0)
      else:
        _t4622 = 0.0
      _t4623 = _t4622
      _gset(_t4621, _t4623)
      _t4624 = _ix((v_gmem_base + 11.0))
      _t4625 = v_trans_sens
      _gset(_t4624, _t4625)
      _t4626 = _ix((v_gmem_base + 12.0))
      _t4627 = v_trans_hold_ms
      _gset(_t4626, _t4627)
      _t4628 = _ix((v_gmem_base + 13.0))
      _t4629 = v_grain_fade
      _gset(_t4628, _t4629)
      _t4630 = _ix((v_gmem_base + 14.0))
      _t4631 = v_slicer_mode
      _gset(_t4630, _t4631)
      _t4632 = _ix((v_gmem_base + 15.0))
      _t4633 = v_slicer_sub
      _gset(_t4632, _t4633)
      _t4634 = _ix((v_gmem_base + 16.0))
      _t4635 = v_slice_decay_ms
      _gset(_t4634, _t4635)
      _t4636 = _ix((v_gmem_base + 17.0))
      _t4637 = v_rev_on
      _gset(_t4636, _t4637)
      _t4638 = _ix((v_gmem_base + 18.0))
      _t4639 = v_pingpong_on
      _gset(_t4638, _t4639)
      _t4640 = _ix((v_gmem_base + 19.0))
      _t4641 = v_feedback
      _gset(_t4640, _t4641)
      _t4642 = _ix((v_gmem_base + 20.0))
      _t4643 = v_degradation
      _gset(_t4642, _t4643)
      _t4644 = _ix((v_gmem_base + 21.0))
      _t4645 = v_stereo_width
      _gset(_t4644, _t4645)
      _t4646 = _ix((v_gmem_base + 22.0))
      _t4647 = v_out_vol
      _gset(_t4646, _t4647)
      _t4648 = _ix((v_gmem_base + 23.0))
      if _tr((1.0 if v_length > 0.0 else 0.0)):
        _t4649 = (_div(v_master_pos, v_length) * 100.0)
      else:
        _t4649 = 0.0
      _t4650 = _t4649
      _gset(_t4648, _t4650)
      _t4651 = _ix((v_gmem_base + 24.0))
      _t4652 = v_cloud_on
      _gset(_t4651, _t4652)
      _t4653 = _ix((v_gmem_base + 25.0))
      _t4654 = v_loop_quant
      _gset(_t4653, _t4654)
      _t4655 = _ix((v_gmem_base + 26.0))
      _t4656 = v_cloud_density
      _gset(_t4655, _t4656)
      _t4657 = _ix((v_gmem_base + 27.0))
      _t4658 = v_cloud_chaos
      _gset(_t4657, _t4658)
      _t4659 = _ix((v_gmem_base + 28.0))
      _t4660 = v_cloud_spread
      _gset(_t4659, _t4660)
      _t4661 = _ix((v_gmem_base + 29.0))
      _t4662 = v_dens_occ
      _gset(_t4661, _t4662)
      _t4663 = _ix((v_gmem_base + 30.0))
      _t4664 = v_dens_len
      _gset(_t4663, _t4664)
      _t4665 = _ix((v_gmem_base + 31.0))
      _t4666 = v_loop_beats
      _gset(_t4665, _t4666)
      _t4667 = _ix((v_gmem_base + 32.0))
      _t4668 = v_slicer_src
      _gset(_t4667, _t4668)
      _t4669 = _ix((v_gmem_base + 33.0))
      _t4670 = v_grid_sub
      _gset(_t4669, _t4670)
      _t4671 = _ix((v_gmem_base + v_gm_pspread_slicer))
      _t4672 = v_slicer_pitch_spread
      _gset(_t4671, _t4672)
      _t4673 = _ix((v_gmem_base + v_gm_pspread_cloud))
      _t4674 = v_cloud_pitch_spread
      _gset(_t4673, _t4674)
      _t4675 = _ix((v_gmem_base + 36.0))
      _t4676 = v_cloud_mix
      _gset(_t4675, _t4676)
      _t4677 = _ix((v_gmem_base + 37.0))
      _t4678 = v_cloud_pos_mode
      _gset(_t4677, _t4678)
      _t4679 = _ix((v_gmem_base + 38.0))
      _t4680 = v_cloud_pos_pct
      _gset(_t4679, _t4680)
      _t4681 = _ix((v_gmem_base + 39.0))
      _t4682 = v_cloud_lfo_shape
      _gset(_t4681, _t4682)
      _t4683 = _ix((v_gmem_base + 40.0))
      _t4684 = v_cloud_lfo_rate
      _gset(_t4683, _t4684)
      _t4685 = _ix((v_gmem_base + 41.0))
      _t4686 = v_cloud_lfo_depth
      _gset(_t4685, _t4686)
      _t4687 = _ix((v_gmem_base + 190.0))
      _t4688 = v_cloud_size
      _gset(_t4687, _t4688)
      _t4689 = _ix((v_gmem_base + 191.0))
      _t4690 = v_cloud_freeze
      _gset(_t4689, _t4690)
      _t4691 = _ix((v_gmem_base + 192.0))
      _t4692 = v_cloud_diffuse
      _gset(_t4691, _t4692)
      _t4693 = _ix((v_gmem_base + 193.0))
      _t4694 = v_slx_mix
      _gset(_t4693, _t4694)
      _t4695 = _ix((v_gmem_base + 194.0))
      _t4696 = v_br_mix
      _gset(_t4695, _t4696)
      _t4697 = _ix((v_gmem_base + 42.0))
      _t4698 = v_active_part
      _gset(_t4697, _t4698)
      _t4699 = _ix((v_gmem_base + 163.0))
      _t4700 = v_pending_part_switch
      _gset(_t4699, _t4700)
      _t4701 = _ix((v_gmem_base + 164.0))
      _t4702 = v_target_part
      _gset(_t4701, _t4702)
      _t4703 = _ix((v_gmem_base + 43.0))
      _t4704 = v_auto_on
      _gset(_t4703, _t4704)
      _t4705 = _ix((v_gmem_base + 44.0))
      _t4706 = v_loop_start
      _gset(_t4705, _t4706)
      _t4707 = _ix((v_gmem_base + 45.0))
      _t4708 = v_loop_width
      _gset(_t4707, _t4708)
      _t4709 = _ix((v_gmem_base + 46.0))
      _t4710 = v_length
      _gset(_t4709, _t4710)
      _t4711 = _ix((v_gmem_base + v_gm_sampler_root))
      _t4712 = v_sampler_root
      _gset(_t4711, _t4712)
      _t4713 = _ix((v_gmem_base + 165.0))
      _t4714 = v_det_thresh
      _gset(_t4713, _t4714)
      _t4715 = _ix((v_gmem_base + 166.0))
      _t4716 = v_det_hold_ms
      _gset(_t4715, _t4716)
      _t4717 = _ix((v_gmem_base + 167.0))
      _t4718 = v_slicer_steps
      _gset(_t4717, _t4718)
      _t4719 = _ix((v_gmem_base + 168.0))
      _t4720 = v_max_slices
      _gset(_t4719, _t4720)
      _t4721 = _ix((v_gmem_base + 169.0))
      _t4722 = v_slicer_preset
      _gset(_t4721, _t4722)
      _t4723 = _ix((v_gmem_base + 170.0))
      _t4724 = v_sampler_release
      _gset(_t4723, _t4724)
      _t4725 = _ix((v_gmem_base + 171.0))
      _t4726 = v_sampler_pitch_mode
      _gset(_t4725, _t4726)
      _t4727 = _ix((v_gmem_base + 174.0))
      _t4728 = v_slice_attack_ms
      _gset(_t4727, _t4728)
      _t4729 = _ix((v_gmem_base + 175.0))
      _t4730 = v_ana_mode
      _gset(_t4729, _t4730)
      _t4731 = _ix((v_gmem_base + 176.0))
      _t4732 = v_src_auto
      _gset(_t4731, _t4732)
      _t4733 = _ix((v_gmem_base + 177.0))
      _t4734 = v_slicer_link
      _gset(_t4733, _t4734)
      _t4735 = _ix((v_gmem_base + v_gm_sampler_armed))
      _t4736 = v_smp_mode
      _gset(_t4735, _t4736)
      _t4737 = _ix((v_gmem_base + v_gm_sampler_pmode))
      _t4738 = v_sampler_pitch_mode
      _gset(_t4737, _t4738)
      _t4739 = _ix((v_gmem_base + v_gm_sampler_release))
      _t4740 = v_sampler_release
      _gset(_t4739, _t4740)
      _t4741 = _ix((v_gmem_base + v_gm_sampler_voices))
      _t4742 = v_smp_nact
      _gset(_t4741, _t4742)
      _t4743 = _ix((v_gmem_base + v_gm_bpm))
      if _tr((1.0 if v_length > 0.0 else 0.0)):
        _t4746 = (60.0 * v_srate)
        _t4745 = f_loop_beat_len()
        _t4744 = _div(_t4746, _t4745)
      else:
        _t4744 = 0.0
      _t4747 = _t4744
      _gset(_t4743, _t4747)
      _t4748 = _ix((v_gmem_base + 172.0))
      _t4749 = v_peak_in_vu
      _gset(_t4748, _t4749)
      _t4750 = _ix((v_gmem_base + 173.0))
      _t4751 = v_peak_out_vu
      _gset(_t4750, _t4751)
      v_param_gmem_base = (110000.0 + (((v_inst_idx * 3.0) + v_p) * 60.0))
      _t4752 = _ix((v_param_gmem_base + 0.0))
      _t4753 = v_speed
      _gset(_t4752, _t4753)
      _t4754 = _ix((v_param_gmem_base + 1.0))
      _t4755 = v_pitch
      _gset(_t4754, _t4755)
      _t4756 = _ix((v_param_gmem_base + 2.0))
      _t4757 = v_mix
      _gset(_t4756, _t4757)
      _t4758 = _ix((v_param_gmem_base + 3.0))
      _t4759 = v_grain_ms
      _gset(_t4758, _t4759)
      _t4760 = _ix((v_param_gmem_base + 4.0))
      _t4761 = v_fade_ms
      _gset(_t4760, _t4761)
      _t4762 = _ix((v_param_gmem_base + 5.0))
      _t4763 = v_play_mode
      _gset(_t4762, _t4763)
      _t4764 = _ix((v_param_gmem_base + 6.0))
      _t4765 = v_link_on
      _gset(_t4764, _t4765)
      _t4766 = _ix((v_param_gmem_base + 7.0))
      _t4767 = v_state_slider
      _gset(_t4766, _t4767)
      _t4768 = _ix((v_param_gmem_base + 8.0))
      _t4769 = v_loop_pos_pct
      _gset(_t4768, _t4769)
      _t4770 = _ix((v_param_gmem_base + 9.0))
      _t4771 = v_trans_sens
      _gset(_t4770, _t4771)
      _t4772 = _ix((v_param_gmem_base + 10.0))
      _t4773 = v_trans_hold_ms
      _gset(_t4772, _t4773)
      _t4774 = _ix((v_param_gmem_base + 11.0))
      _t4775 = v_grain_fade
      _gset(_t4774, _t4775)
      _t4776 = _ix((v_param_gmem_base + 12.0))
      _t4777 = v_slicer_mode
      _gset(_t4776, _t4777)
      _t4778 = _ix((v_param_gmem_base + 13.0))
      _t4779 = v_slicer_sub
      _gset(_t4778, _t4779)
      _t4780 = _ix((v_param_gmem_base + 14.0))
      _t4781 = v_slice_decay_ms
      _gset(_t4780, _t4781)
      _t4782 = _ix((v_param_gmem_base + 15.0))
      _t4783 = v_rev_on
      _gset(_t4782, _t4783)
      _t4784 = _ix((v_param_gmem_base + 16.0))
      _t4785 = v_pingpong_on
      _gset(_t4784, _t4785)
      _t4786 = _ix((v_param_gmem_base + 17.0))
      _t4787 = v_feedback
      _gset(_t4786, _t4787)
      _t4788 = _ix((v_param_gmem_base + 18.0))
      _t4789 = v_degradation
      _gset(_t4788, _t4789)
      _t4790 = _ix((v_param_gmem_base + 19.0))
      _t4791 = v_stereo_width
      _gset(_t4790, _t4791)
      _t4792 = _ix((v_param_gmem_base + 20.0))
      _t4793 = v_out_vol
      _gset(_t4792, _t4793)
      _t4794 = _ix((v_param_gmem_base + 21.0))
      _t4795 = v_ghost_pos_pct
      _gset(_t4794, _t4795)
      _t4796 = _ix((v_param_gmem_base + 22.0))
      _t4797 = v_cloud_on
      _gset(_t4796, _t4797)
      _t4798 = _ix((v_param_gmem_base + 23.0))
      _t4799 = v_loop_quant
      _gset(_t4798, _t4799)
      _t4800 = _ix((v_param_gmem_base + 24.0))
      _t4801 = v_cloud_density
      _gset(_t4800, _t4801)
      _t4802 = _ix((v_param_gmem_base + 25.0))
      _t4803 = v_cloud_chaos
      _gset(_t4802, _t4803)
      _t4804 = _ix((v_param_gmem_base + 26.0))
      _t4805 = v_cloud_spread
      _gset(_t4804, _t4805)
      _t4806 = _ix((v_param_gmem_base + 27.0))
      _t4807 = v_dens_occ
      _gset(_t4806, _t4807)
      _t4808 = _ix((v_param_gmem_base + 28.0))
      _t4809 = v_dens_len
      _gset(_t4808, _t4809)
      _t4810 = _ix((v_param_gmem_base + 29.0))
      _t4811 = v_loop_beats
      _gset(_t4810, _t4811)
      _t4812 = _ix((v_param_gmem_base + 30.0))
      _t4813 = v_slicer_src
      _gset(_t4812, _t4813)
      _t4814 = _ix((v_param_gmem_base + 31.0))
      _t4815 = v_grid_sub
      _gset(_t4814, _t4815)
      _t4816 = _ix((v_param_gmem_base + 32.0))
      _t4817 = v_slicer_pitch_spread
      _gset(_t4816, _t4817)
      _t4818 = _ix((v_param_gmem_base + 33.0))
      _t4819 = v_cloud_pitch_spread
      _gset(_t4818, _t4819)
      _t4820 = _ix((v_param_gmem_base + 34.0))
      _t4821 = v_cloud_mix
      _gset(_t4820, _t4821)
      _t4822 = _ix((v_param_gmem_base + 35.0))
      _t4823 = v_cloud_pos_mode
      _gset(_t4822, _t4823)
      _t4824 = _ix((v_param_gmem_base + 36.0))
      _t4825 = v_cloud_pos_pct
      _gset(_t4824, _t4825)
      _t4826 = _ix((v_param_gmem_base + 37.0))
      _t4827 = v_cloud_lfo_shape
      _gset(_t4826, _t4827)
      _t4828 = _ix((v_param_gmem_base + 38.0))
      _t4829 = v_cloud_lfo_rate
      _gset(_t4828, _t4829)
      _t4830 = _ix((v_param_gmem_base + 39.0))
      _t4831 = v_cloud_lfo_depth
      _gset(_t4830, _t4831)
      _t4832 = _ix((v_param_gmem_base + 40.0))
      _t4833 = v_looper_hue
      _gset(_t4832, _t4833)
      _t4834 = _ix((v_param_gmem_base + 41.0))
      _t4835 = v_sampler_root
      _gset(_t4834, _t4835)
      _t4836 = _ix((v_param_gmem_base + 42.0))
      _t4837 = v_sampler_pitch_mode
      _gset(_t4836, _t4837)
      _t4838 = _ix((v_param_gmem_base + 43.0))
      _t4839 = v_sampler_release
      _gset(_t4838, _t4839)
      _t4840 = _ix((v_param_gmem_base + 44.0))
      _t4841 = v_manual_id
      _gset(_t4840, _t4841)
      _t4842 = _ix((v_param_gmem_base + 45.0))
      _t4843 = v_clk_src
      _gset(_t4842, _t4843)
      _t4844 = _ix((v_param_gmem_base + 46.0))
      _t4845 = v_slicer_steps
      _gset(_t4844, _t4845)
      _t4846 = _ix((v_param_gmem_base + 47.0))
      _t4847 = v_max_slices
      _gset(_t4846, _t4847)
      _t4848 = _ix((v_param_gmem_base + 48.0))
      _t4849 = v_slicer_preset
      _gset(_t4848, _t4849)
      _t4850 = _ix((v_param_gmem_base + 49.0))
      _t4851 = v_det_thresh
      _gset(_t4850, _t4851)
      _t4852 = _ix((v_param_gmem_base + 50.0))
      _t4853 = v_det_hold_ms
      _gset(_t4852, _t4853)
      _t4854 = _ix((v_param_gmem_base + 51.0))
      _t4855 = v_dub_grain_ms
      _gset(_t4854, _t4855)
      _t4856 = _ix((v_param_gmem_base + 52.0))
      _t4857 = v_dub_align_ms
      _gset(_t4856, _t4857)
      _t4858 = _ix((v_param_gmem_base + 53.0))
      _t4859 = v_read_align_ms
      _gset(_t4858, _t4859)
      _t4860 = _ix((v_param_gmem_base + 54.0))
      _t4861 = v_cloud_size
      _gset(_t4860, _t4861)
      _t4862 = _ix((v_param_gmem_base + 55.0))
      _t4863 = v_cloud_freeze
      _gset(_t4862, _t4863)
      _t4864 = _ix((v_param_gmem_base + 56.0))
      _t4865 = v_slicer_link
      _gset(_t4864, _t4865)
      _t4866 = _ix((v_param_gmem_base + 57.0))
      _t4867 = v_instance_id
      _gset(_t4866, _t4867)
      _t4868 = _ix((v_param_gmem_base + 58.0))
      _t4869 = v_active_part
      _gset(_t4868, _t4869)
      _t4870 = _ix((v_param_gmem_base + 59.0))
      _t4871 = 1.0
      _gset(_t4870, _t4871)
      v_wave_export_slots = 100.0
      if _tr((1.0 if v_length > 0.0 else 0.0)):
        _t4872 = v_length
      else:
        _t4873 = 1.0 if _tr((1.0 if abs(v_state - 1.0) < 0.00001 else 0.0)) else 0.0
        if not _t4873:
          _t4873 = 1.0 if _tr((1.0 if abs(v_state - 8.0) < 0.00001 else 0.0)) else 0.0
        if _tr(_t4873):
          _t4874 = v_pos
        else:
          _t4874 = 0.0
        _t4872 = _t4874
      v_max_len_exp = _t4872
      if _tr((1.0 if v_max_len_exp > 0.0 else 0.0)):
        v_wi_ex = 0.0
        v_w_step_ex = _div(v_max_len_exp, v_wave_export_slots)
        for _t4876 in range(max(0, int(v_wave_export_slots))):
          v_w_val_ex = 0.0
          v_wk_ex = 0.0
          for _t4877 in range(max(0, int(4.0))):
            _t4878 = ((v_wi_ex * v_w_step_ex) + ((v_wk_ex * v_w_step_ex) * 0.25))
            _t4879 = _floor(_t4878)
            v_w_idx_ex = _t4879
            _t4880 = _mget(v_left_buf + v_w_idx_ex)
            _t4881 = abs(_t4880)
            _t4882 = _t4881
            _t4883 = _mget(v_right_buf + v_w_idx_ex)
            _t4884 = abs(_t4883)
            _t4885 = _t4884
            _t4886 = max(_t4882, _t4885)
            v_w_tmp_ex = _t4886
            if _tr((1.0 if v_w_tmp_ex > v_w_val_ex else 0.0)):
              v_w_val_ex = v_w_tmp_ex
              _t4887 = v_w_val_ex
            else:
              _t4887 = 0.0
            v_wk_ex = (v_wk_ex + 1.0)
          _t4888 = _ix(((v_gmem_base + 50.0) + v_wi_ex))
          _t4889 = v_w_val_ex
          _gset(_t4888, _t4889)
          v_wi_ex = (v_wi_ex + 1.0)
        _t4875 = 0.0
      else:
        v_wi_ex = 0.0
        for _t4890 in range(max(0, int(100.0))):
          _t4891 = _ix(((v_gmem_base + 50.0) + v_wi_ex))
          _t4892 = 0.0
          _gset(_t4891, _t4892)
          v_wi_ex = (v_wi_ex + 1.0)
        _t4875 = 0.0
      v_slice_gmem_base = (100000.0 + (((v_inst_idx * 3.0) + (v_active_part - 1.0)) * 259.0))
      _t4893 = _ix(v_slice_gmem_base)
      _t4894 = v_trans_count
      _t4895 = v_max_transients
      _t4896 = min(_t4894, _t4895)
      _t4897 = _t4896
      _gset(_t4893, _t4897)
      _t4898 = _ix((v_slice_gmem_base + 1.0))
      _t4899 = v_loop_start
      _gset(_t4898, _t4899)
      _t4900 = _ix((v_slice_gmem_base + 2.0))
      _t4901 = v_loop_width
      _gset(_t4900, _t4901)
      v_slice_gmem_i = 0.0
      for _t4902 in range(max(0, int(v_max_transients))):
        _t4903 = _ix(((v_slice_gmem_base + 3.0) + v_slice_gmem_i))
        if _tr((1.0 if v_slice_gmem_i < v_trans_count else 0.0)):
          _t4905 = (_mget(v_trans_mem + v_slice_gmem_i) - v_loop_start)
          _t4906 = max(0.0, _t4905)
          _t4904 = _t4906
        else:
          _t4904 = 0.0
        _t4907 = _t4904
        _gset(_t4903, _t4907)
        v_slice_gmem_i = (v_slice_gmem_i + 1.0)
      _t4602 = 0.0
    else:
      _t4908 = _ix((v_gmem_base + 2.0))
      _t4909 = 0.0
      _gset(_t4908, _t4909)
      if _tr((1.0 if abs(v_p - 0.0) < 0.00001 else 0.0)):
        _t4910 = v_len_part1
      else:
        if _tr((1.0 if abs(v_p - 1.0) < 0.00001 else 0.0)):
          _t4911 = v_len_part2
        else:
          _t4911 = v_len_part3
        _t4910 = _t4911
      v_p_len = _t4910
      _t4912 = _ix((v_gmem_base + 46.0))
      _t4913 = v_p_len
      _gset(_t4912, _t4913)
      _t4914 = _ix((v_gmem_base + 10.0))
      _t4915 = 0.0
      _gset(_t4914, _t4915)
      _t4916 = _ix((v_gmem_base + 23.0))
      _t4917 = 0.0
      _gset(_t4916, _t4917)
      _t4918 = _ix((v_gmem_base + 42.0))
      _t4919 = v_active_part
      _gset(_t4918, _t4919)
      _t4920 = _ix((v_gmem_base + 163.0))
      _t4921 = v_pending_part_switch
      _gset(_t4920, _t4921)
      _t4922 = _ix((v_gmem_base + 164.0))
      _t4923 = v_target_part
      _gset(_t4922, _t4923)
      if _tr((1.0 if abs(v_p_len - 0.0) < 0.00001 else 0.0)):
        v_wi_ex = 0.0
        for _t4925 in range(max(0, int(100.0))):
          _t4926 = _ix(((v_gmem_base + 50.0) + v_wi_ex))
          _t4927 = 0.0
          _gset(_t4926, _t4927)
          v_wi_ex = (v_wi_ex + 1.0)
        _t4924 = 0.0
      else:
        _t4924 = 0.0
      _t4602 = _t4924
    v_p = (v_p + 1.0)
  return 0

def sec_sample():
  global v_acc_cur_dirty, v_acc_ok, v_active_part, v_an_wrap_pending, v_analysing, v_ar_att, v_ar_cnt, v_ar_dn, v_ar_hold, v_ar_in, v_ar_k, v_ar_lp, v_ar_rel, v_ar_up, v_ar_x, v_auto_above_prev, v_auto_on, v_auto_rep_active, v_auto_rep_hold_counter, v_base_backup_l, v_base_backup_r, v_base_cloud_center, v_base_gt_ms, v_base_len_part1, v_base_len_part2, v_base_len_part3, v_base_loop_length, v_base_mix_factor, v_beats_per_step, v_bg_dg, v_bg_env, v_bg_fr, v_bg_fs, v_bg_l, v_bg_len, v_bg_p0, v_bg_p1, v_bg_p2, v_bg_p3, v_bg_r, v_bg_rp, v_bg_wg, v_br_bg_clk, v_br_bg_e, v_br_bg_pos, v_br_bg_s, v_br_mix, v_br_mix_s, v_br_on, v_buf_len, v_c_factor, v_cl_a, v_cl_act, v_cl_atk, v_cl_base, v_cl_bl, v_cl_br, v_cl_c, v_cl_center, v_cl_dec, v_cl_dl, v_cl_dr, v_cl_fr, v_cl_g, v_cl_i0, v_cl_i1, v_cl_i2, v_cl_i3, v_cl_l, v_cl_latt, v_cl_lc, v_cl_ld, v_cl_lg, v_cl_lh, v_cl_li, v_cl_lk, v_cl_lpk, v_cl_lrel, v_cl_lt, v_cl_lth, v_cl_m, v_cl_max, v_cl_mean, v_cl_mem, v_cl_n, v_cl_on_prev, v_cl_out_l, v_cl_out_r, v_cl_p, v_cl_ph, v_cl_r, v_cl_snap, v_cl_spr, v_cl_stride, v_cl_timer, v_cl_w, v_cl_wl, v_cl_ws, v_cl_wsum, v_cl_x, v_clk_cyc, v_clk_cyc1, v_clk_cyc2, v_clk_cyc3, v_clk_len_ref, v_clock_abs_pos, v_cloud_center, v_cloud_center_draw, v_cloud_chaos, v_cloud_density, v_cloud_diffuse, v_cloud_freeze, v_cloud_lfo_depth, v_cloud_lfo_phase, v_cloud_lfo_rate, v_cloud_lfo_shape, v_cloud_mix, v_cloud_on, v_cloud_pitch_spread, v_cloud_pos_mode, v_cloud_pos_pct, v_cloud_size, v_cloud_spread, v_cloud_x, v_cm_active, v_cmx, v_co_p, v_co_rec, v_curr_peak, v_curr_samp, v_current_slice_pitch, v_current_step_calc, v_d_norm, v_degradation, v_delay_buf_l, v_delay_buf_r, v_delay_idx, v_delay_len, v_dens_first, v_dens_force, v_dens_g, v_dens_next_on, v_dens_occ, v_dens_on, v_dens_prev_state, v_dens_seg, v_dens_slew, v_dens_slot, v_dens_t, v_dens_tgt, v_dens_ton, v_df_a1, v_df_a2, v_df_a3, v_df_a4, v_df_b1, v_df_b2, v_df_b3, v_df_b4, v_df_d, v_df_dl, v_df_dr, v_df_fb, v_df_fl, v_df_fr, v_df_k, v_df_lp_l, v_df_lp_r, v_df_on, v_df_w, v_df_xl, v_df_xr, v_dirty_len, v_dist_from_end, v_dry_gain, v_dub_g, v_dub_gran, v_dub_gran_prev, v_dub_pan, v_dub_pf, v_dub_pfk, v_eff_end, v_eff_len, v_eff_start, v_effective_pitch_ratio, v_effective_rev, v_env, v_f_samps, v_fade_ms, v_fade_samps, v_feedback, v_flutter_mod, v_flutter_phase, v_force_mode_exit, v_frac, v_frz_center, v_frz_l, v_frz_len, v_frz_prev, v_frz_r, v_frz_ready, v_g_base, v_g_dens, v_g_dir, v_g_dur, v_g_l, v_g_main, v_g_mono, v_g_pan, v_g_phase, v_g_pitch_off, v_g_r, v_gh_l, v_gh_r, v_ghost_pos_pct, v_gi, v_gl_gain, v_gmem, v_gr_gain, v_grain_data_size, v_grain_dur, v_grain_mem, v_grain_mix, v_grain_ms, v_grain_pitch_mult, v_grain_target, v_gran_now, v_granular_l, v_granular_r, v_gt, v_hist_redo, v_hist_undo, v_history_count, v_history_head, v_hold_samples_left, v_ih_l, v_ih_mask, v_ih_n, v_ih_r, v_in0, v_in1, v_init_done, v_input_env, v_input_signal_active, v_instance_alias, v_instance_id, v_is_dubbing, v_is_normal_playback, v_is_one_shot_mode, v_is_recording, v_is_slave, v_last_slicer_step, v_last_state_target, v_lat_samps, v_leave_oneshot, v_leave_slicer, v_leave_stop, v_left_buf, v_len_part1, v_len_part2, v_len_part3, v_length, v_lfo_offset, v_lfo_val, v_link_eff, v_link_on, v_loop_env_pos, v_loop_envelope, v_loop_start, v_loop_width, v_lp_mute, v_master_pos, v_master_pos1, v_master_pos2, v_master_pos3, v_max_grains, v_mclk_cyc, v_mclk_hb, v_mclk_len, v_mclk_on, v_mclk_pos, v_mclk_trk, v_mclk_valid, v_min_fade_samps, v_mix, v_ml_cool, v_ml_fwd_free, v_ml_guard, v_ml_ok, v_ml_trig, v_ms_off, v_mult_len, v_mute_g, v_need_resync, v_num_active_voices, v_ofrac, v_old_pos, v_old_pos_ptr, v_old_s0, v_old_s1, v_old_safe_pos, v_one_shot_playing, v_one_shot_pp_state, v_op0, v_op1, v_op2, v_op3, v_out0, v_out1, v_out_vol, v_p0, v_p1, v_p2, v_p3, v_p_ang, v_p_norm, v_p_off, v_pan_ol, v_pan_or, v_param_smooth_coeff, v_part_sp, v_pd_arm, v_pd_k, v_pd_l, v_pd_prev_l, v_pd_prev_r, v_pd_r, v_peak_in_vu, v_peak_loop_vu, v_peak_out_vu, v_pending_next_state, v_pending_part_switch, v_ping_pong_dir, v_pingpong_on, v_pitch, v_pitch_ratio, v_play_mode, v_play_mode_changed, v_play_this_slice, v_pos, v_pos_step, v_pos_step_actual, v_prev_cloud_on, v_prev_in0, v_prev_in1, v_prev_loop_start, v_prev_loop_width, v_prev_normal_playback, v_prev_pingpong_on, v_prev_pitch_ratio_sig, v_prev_play_mode, v_prev_rev_on, v_prev_sm_speed, v_prev_state_for_sync, v_prev_sync_key, v_qs_hit, v_qs_i, v_qs_prev, v_qs_snap, v_qs_wait, v_rand_pitch_idx, v_rate_t, v_rd_dl, v_rd_f, v_rd_frac, v_rd_i, v_rd_last_g, v_rd_last_l, v_rd_last_p, v_rd_last_pamt, v_rd_last_pan, v_rd_last_r, v_rd_last_st, v_rd_last_we, v_rd_last_ws, v_rd_ph, v_rd_prev_dur, v_rd_prev_n, v_rd_prev_ok, v_rd_prev_start, v_rd_sn, v_rd_valid, v_rd_wn, v_read_align_ms, v_read_idx, v_rec_cmd, v_rec_force_free, v_rec_lag_pend, v_rec_speed, v_rec_start_lag, v_rec_start_time, v_rec_stop_lag, v_rel_pos, v_replace_fade, v_replace_fade_coeff, v_rev_changed, v_rev_on, v_right_buf, v_rnd_factor, v_rnd_idx, v_rp0, v_rp1, v_rp2, v_rp3, v_rp_cnt, v_rp_pend, v_rp_tail_on, v_rs_to, v_s0, v_s0_safe, v_s1, v_s1_safe, v_safe_pos, v_samples_per_step, v_seq_mem, v_sl_gate, v_sl_hi, v_sl_lo, v_sl_pan_amt, v_sl_pan_k, v_sl_pre_t, v_sl_rd, v_sl_rec, v_sl_run, v_sl_slew, v_slice_att, v_slice_att_eff_ms, v_slice_att_step, v_slice_attack_ms, v_slice_decay_ms, v_slice_decay_step, v_slice_end_dist, v_slice_env, v_slice_g, v_slice_hold, v_slice_mute_gate, v_slice_mute_step, v_slice_mute_target, v_slice_pan, v_slice_pitch_mem, v_slice_pitch_mult, v_slicer_current_step, v_slicer_mode, v_slicer_sample_counter, v_slicer_sub, v_slw_last, v_slx_clk, v_slx_dg, v_slx_env, v_slx_fr, v_slx_fs, v_slx_l, v_slx_mix, v_slx_mix_s, v_slx_p0, v_slx_p1, v_slx_p2, v_slx_p3, v_slx_pos, v_slx_prev, v_slx_r, v_slx_rp, v_slx_wg, v_sm_pitch, v_sm_speed, v_smooth_start, v_smooth_width, v_smp_alloff, v_smp_armed, v_smp_ev_i, v_smp_ev_n, v_smp_ev_note, v_smp_ev_vel, v_smp_kmode, v_smp_l, v_smp_mode, v_smp_prev_mode, v_smp_quick_rel, v_smp_r, v_spawn_target_pos, v_spawn_timer, v_speed, v_spl0, v_spl1, v_spread_offset, v_srate, v_state, v_state_target, v_state_transition_fade, v_step_len, v_stereo_width, v_sw_on, v_sw_pos, v_sync_a, v_sync_b, v_sync_c_l, v_sync_c_r, v_sync_c_w, v_sync_dev, v_sync_exp, v_sync_hard_resync, v_sync_key, v_target_grain_ms, v_target_gt_ms, v_target_part, v_target_pos, v_target_sync_len, v_tempo, v_total_w, v_trans_count, v_trans_hold_ms, v_trans_mem, v_trans_sens, v_varispeed, v_vu_rel, v_wet_gain, v_wet_s0, v_wet_s1, v_wow_mod, v_wow_phase, v_wr_guard, v_wr_off, v_wrapped, v_x_event, v_x_free, v_x_mode, v_x_ms, v_x_per, v_x_ph_prev, v_xa, v_xarm, v_xb, v_xf_eqp, v_xf_g, v_xf_inc, v_xf_k, v_xf_l, v_xf_len_jump, v_xf_len_rs, v_xf_on, v_xf_p, v_xf_pamt, v_xf_pan, v_xf_r, v_xf_st, v_xf_w, v_xf_we, v_xf_ws, v_xfade_coeff, v_xfade_gain, v_xfade_pos_active, v_xfade_pos_count, v_xfade_pos_len, v_xfr, v_xi_s, v_xp, v_xper, v_xph, v_xq0, v_xq1, v_xq2, v_xq3
  v_in0 = v_spl0
  v_in1 = v_spl1
  v_wet_s0 = 0.0
  v_wet_s1 = 0.0
  _t4928 = 1.0 if _tr(v_cloud_on) else 0.0
  if _t4928:
    _t4928 = 1.0 if _tr((0.0 if _tr(v_cl_on_prev) else 1.0)) else 0.0
  if _tr(_t4928):
    v_cl_snap = 1.0
    _t4929 = v_cl_snap
  else:
    _t4929 = 0.0
  v_cl_on_prev = v_cloud_on
  v_qs_i = (v_qs_i + 1.0)
  v_pos_step = 0.0
  _t4930 = (v_peak_in_vu * v_vu_rel)
  _t4931 = v_in0
  _t4932 = abs(_t4931)
  _t4933 = _t4932
  _t4934 = v_in1
  _t4935 = abs(_t4934)
  _t4936 = _t4935
  _t4937 = max(_t4933, _t4936)
  _t4938 = _t4937
  _t4939 = max(_t4930, _t4938)
  v_peak_in_vu = _t4939
  v_ms_off = ((v_active_part - 1.0) * 10.0)
  _t4941 = 1.0 if _tr((1.0 if _gget(v_ms_off) > 0.0 else 0.0)) else 0.0
  if _t4941:
    _t4941 = 1.0 if _tr((0.0 if abs(_gget((v_ms_off + 1.0)) - v_instance_id) < 0.00001 else 1.0)) else 0.0
  _t4940 = 1.0 if _tr(_t4941) else 0.0
  if _t4940:
    _t4940 = 1.0 if _tr((0.0 if abs(_gget((v_ms_off + 1.0)) - v_instance_alias) < 0.00001 else 1.0)) else 0.0
  v_is_slave = _t4940
  _t4942 = 1.0 if _tr(v_is_slave) else 0.0
  if _t4942:
    _t4942 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
  if _tr(_t4942):
    v_master_pos = (v_master_pos + 1.0)
    if _tr((1.0 if v_master_pos >= v_length else 0.0)):
      v_master_pos = (v_master_pos - v_length)
      v_clk_cyc = _mod((v_clk_cyc + 1.0), 840.0)
      v_slicer_sample_counter = 1000000000.0
      if _tr((0.0 if abs(v_rp_pend - 0.0) < 0.00001 else 1.0)):
        v_master_pos = (v_master_pos + v_rp_pend)
        _t4948 = v_length
        _t4946 = _div(v_master_pos, v_length)
        _t4947 = _floor(_t4946)
        v_master_pos = (v_master_pos - (_t4948 * _t4947))
        v_rp_pend = 0.0
        v_rp_cnt = 0.0
        v_sync_hard_resync = 1.0
        _t4945 = v_sync_hard_resync
      else:
        _t4945 = 0.0
      _t4944 = _t4945
    else:
      _t4944 = 0.0
    if _tr((1.0 if abs(v_active_part - 1.0) < 0.00001 else 0.0)):
      v_master_pos1 = v_master_pos
      _t4949 = v_master_pos1
    else:
      if _tr((1.0 if abs(v_active_part - 2.0) < 0.00001 else 0.0)):
        v_master_pos2 = v_master_pos
        _t4950 = v_master_pos2
      else:
        v_master_pos3 = v_master_pos
        _t4950 = v_master_pos3
      _t4949 = _t4950
    _t4943 = _t4949
  else:
    if _tr((1.0 if v_len_part1 > 0.0 else 0.0)):
      v_master_pos1 = (v_master_pos1 + 1.0)
      if _tr((1.0 if v_master_pos1 >= v_len_part1 else 0.0)):
        v_master_pos1 = (v_master_pos1 - v_len_part1)
        if _tr((1.0 if abs(v_active_part - 1.0) < 0.00001 else 0.0)):
          v_clk_cyc = _mod((v_clk_cyc + 1.0), 840.0)
          v_slicer_sample_counter = 1000000000.0
          _t4953 = v_slicer_sample_counter
        else:
          _t4953 = 0.0
        _t4952 = _t4953
      else:
        _t4952 = 0.0
      _t4954 = 1.0 if _tr((1.0 if abs(_gget(0.0) - 1.0) < 0.00001 else 0.0)) else 0.0
      if _t4954:
        _t4955 = 1.0 if _tr((1.0 if abs(_gget(1.0) - v_instance_id) < 0.00001 else 0.0)) else 0.0
        if not _t4955:
          _t4955 = 1.0 if _tr((1.0 if abs(_gget(1.0) - v_instance_alias) < 0.00001 else 0.0)) else 0.0
        _t4954 = 1.0 if _tr(_t4955) else 0.0
      if _tr(_t4954):
        _t4957 = _ix(2.0)
        if _tr((1.0 if v_base_len_part1 > 0.0 else 0.0)):
          _t4958 = v_base_len_part1
        else:
          _t4958 = v_len_part1
        _t4959 = _t4958
        _gset(_t4957, _t4959)
        _t4960 = _ix(3.0)
        _t4961 = v_master_pos1
        _gset(_t4960, _t4961)
        _t4962 = _ix(4.0)
        if _tr((1.0 if abs(v_active_part - 1.0) < 0.00001 else 0.0)):
          _t4963 = v_clk_cyc
        else:
          _t4963 = v_clk_cyc1
        _t4964 = _t4963
        _gset(_t4962, _t4964)
        _t4956 = _t4964
      else:
        _t4956 = 0.0
      _t4951 = _t4956
    else:
      _t4951 = 0.0
    if _tr((1.0 if v_len_part2 > 0.0 else 0.0)):
      v_master_pos2 = (v_master_pos2 + 1.0)
      if _tr((1.0 if v_master_pos2 >= v_len_part2 else 0.0)):
        v_master_pos2 = (v_master_pos2 - v_len_part2)
        if _tr((1.0 if abs(v_active_part - 2.0) < 0.00001 else 0.0)):
          v_clk_cyc = _mod((v_clk_cyc + 1.0), 840.0)
          v_slicer_sample_counter = 1000000000.0
          _t4967 = v_slicer_sample_counter
        else:
          _t4967 = 0.0
        _t4966 = _t4967
      else:
        _t4966 = 0.0
      _t4968 = 1.0 if _tr((1.0 if abs(_gget(10.0) - 1.0) < 0.00001 else 0.0)) else 0.0
      if _t4968:
        _t4969 = 1.0 if _tr((1.0 if abs(_gget(11.0) - v_instance_id) < 0.00001 else 0.0)) else 0.0
        if not _t4969:
          _t4969 = 1.0 if _tr((1.0 if abs(_gget(11.0) - v_instance_alias) < 0.00001 else 0.0)) else 0.0
        _t4968 = 1.0 if _tr(_t4969) else 0.0
      if _tr(_t4968):
        _t4971 = _ix(12.0)
        if _tr((1.0 if v_base_len_part2 > 0.0 else 0.0)):
          _t4972 = v_base_len_part2
        else:
          _t4972 = v_len_part2
        _t4973 = _t4972
        _gset(_t4971, _t4973)
        _t4974 = _ix(13.0)
        _t4975 = v_master_pos2
        _gset(_t4974, _t4975)
        _t4976 = _ix(14.0)
        if _tr((1.0 if abs(v_active_part - 2.0) < 0.00001 else 0.0)):
          _t4977 = v_clk_cyc
        else:
          _t4977 = v_clk_cyc2
        _t4978 = _t4977
        _gset(_t4976, _t4978)
        _t4970 = _t4978
      else:
        _t4970 = 0.0
      _t4965 = _t4970
    else:
      _t4965 = 0.0
    if _tr((1.0 if v_len_part3 > 0.0 else 0.0)):
      v_master_pos3 = (v_master_pos3 + 1.0)
      if _tr((1.0 if v_master_pos3 >= v_len_part3 else 0.0)):
        v_master_pos3 = (v_master_pos3 - v_len_part3)
        if _tr((1.0 if abs(v_active_part - 3.0) < 0.00001 else 0.0)):
          v_clk_cyc = _mod((v_clk_cyc + 1.0), 840.0)
          v_slicer_sample_counter = 1000000000.0
          _t4981 = v_slicer_sample_counter
        else:
          _t4981 = 0.0
        _t4980 = _t4981
      else:
        _t4980 = 0.0
      _t4982 = 1.0 if _tr((1.0 if abs(_gget(20.0) - 1.0) < 0.00001 else 0.0)) else 0.0
      if _t4982:
        _t4983 = 1.0 if _tr((1.0 if abs(_gget(21.0) - v_instance_id) < 0.00001 else 0.0)) else 0.0
        if not _t4983:
          _t4983 = 1.0 if _tr((1.0 if abs(_gget(21.0) - v_instance_alias) < 0.00001 else 0.0)) else 0.0
        _t4982 = 1.0 if _tr(_t4983) else 0.0
      if _tr(_t4982):
        _t4985 = _ix(22.0)
        if _tr((1.0 if v_base_len_part3 > 0.0 else 0.0)):
          _t4986 = v_base_len_part3
        else:
          _t4986 = v_len_part3
        _t4987 = _t4986
        _gset(_t4985, _t4987)
        _t4988 = _ix(23.0)
        _t4989 = v_master_pos3
        _gset(_t4988, _t4989)
        _t4990 = _ix(24.0)
        if _tr((1.0 if abs(v_active_part - 3.0) < 0.00001 else 0.0)):
          _t4991 = v_clk_cyc
        else:
          _t4991 = v_clk_cyc3
        _t4992 = _t4991
        _gset(_t4990, _t4992)
        _t4984 = _t4992
      else:
        _t4984 = 0.0
      _t4979 = _t4984
    else:
      _t4979 = 0.0
    if _tr((1.0 if abs(v_active_part - 1.0) < 0.00001 else 0.0)):
      v_master_pos = v_master_pos1
      _t4993 = v_master_pos
    else:
      if _tr((1.0 if abs(v_active_part - 2.0) < 0.00001 else 0.0)):
        v_master_pos = v_master_pos2
        _t4994 = v_master_pos
      else:
        v_master_pos = v_master_pos3
        _t4994 = v_master_pos
      _t4993 = _t4994
    _t4943 = _t4993
  _t4995 = v_in0
  _t4996 = abs(_t4995)
  _t4997 = _t4996
  _t4998 = v_in1
  _t4999 = abs(_t4998)
  _t5000 = _t4999
  _t5001 = max(_t4997, _t5000)
  v_curr_peak = _t5001
  v_ih_n = (v_ih_n + 1.0)
  if _tr((1.0 if v_ih_n >= 1073741824.0 else 0.0)):
    _t5003 = f_ih_wrap()
    _t5002 = _t5003
  else:
    _t5002 = 0.0
  _t5004 = _ix(v_ih_l + float(int(v_ih_n) & int(v_ih_mask)))
  _t5005 = v_in0
  _mset(_t5004, _t5005)
  _t5006 = _ix(v_ih_r + float(int(v_ih_n) & int(v_ih_mask)))
  _t5007 = v_in1
  _mset(_t5006, _t5007)
  if _tr((1.0 if v_curr_peak >= v_trans_sens else 0.0)):
    v_input_signal_active = 1.0
    v_hold_samples_left = (v_srate * (v_trans_hold_ms * 0.001))
    _t5008 = v_hold_samples_left
  else:
    if _tr((1.0 if v_hold_samples_left > 0.0 else 0.0)):
      v_hold_samples_left = (v_hold_samples_left - 1.0)
      v_input_signal_active = 1.0
      _t5009 = v_input_signal_active
    else:
      v_input_signal_active = 0.0
      _t5009 = v_input_signal_active
    _t5008 = _t5009
  if _tr((1.0 if abs(v_init_done - 0.0) < 0.00001 else 0.0)):
    v_sm_pitch = v_pitch
    v_sm_speed = v_speed
    v_init_done = 1.0
    _t5010 = v_init_done
  else:
    _t5010 = 0.0
  v_sm_pitch = (v_sm_pitch + ((v_pitch - v_sm_pitch) * 0.005))
  v_sm_speed = (v_sm_speed + ((v_speed - v_sm_speed) * 0.005))
  v_pitch_ratio = _pow(2.0, _div(v_sm_pitch, 12.0))
  v_varispeed = (v_sm_speed * v_pitch_ratio)
  v_rec_speed = v_varispeed
  _t5012 = 1.0 if _tr(v_link_on) else 0.0
  if not _t5012:
    _t5012 = 1.0 if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)) else 0.0
  _t5011 = 1.0 if _tr(_t5012) else 0.0
  if not _t5011:
    _t5011 = 1.0 if _tr(v_cloud_on) else 0.0
  v_link_eff = _t5011
  v_is_one_shot_mode = (1.0 if abs(v_play_mode - 2.0) < 0.00001 else 0.0)
  if _tr((1.0 if v_slice_decay_ms > 1950.0 else 0.0)):
    _t5013 = v_slice_attack_ms
  else:
    _t5014 = v_slice_attack_ms
    _t5015 = v_slice_decay_ms
    _t5016 = min(_t5014, _t5015)
    _t5013 = _t5016
  v_slice_att_eff_ms = _t5013
  _t5017 = 1.0 if _tr(v_mclk_trk) else 0.0
  if _t5017:
    _t5017 = 1.0 if _tr(v_mclk_valid) else 0.0
  if _tr(_t5017):
    v_mclk_pos = (v_mclk_pos + 1.0)
    if _tr((1.0 if v_mclk_pos >= v_mclk_len else 0.0)):
      v_mclk_pos = (v_mclk_pos - v_mclk_len)
      v_mclk_cyc = _mod((v_mclk_cyc + 1.0), 840.0)
      _t5019 = v_mclk_cyc
    else:
      _t5019 = 0.0
    _t5018 = _t5019
  else:
    _t5018 = 0.0
  _t5021 = 1.0 if _tr((1.0 if v_state >= 2.0 else 0.0)) else 0.0
  if _t5021:
    _t5021 = 1.0 if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)) else 0.0
  _t5020 = 1.0 if _tr(_t5021) else 0.0
  if _t5020:
    _t5020 = 1.0 if _tr((1.0 if v_trans_count > 0.0 else 0.0)) else 0.0
  if _tr(_t5020):
    if _tr((1.0 if abs(v_slicer_sub - 0.0) < 0.00001 else 0.0)):
      _t5023 = 1.0
    else:
      if _tr((1.0 if abs(v_slicer_sub - 1.0) < 0.00001 else 0.0)):
        _t5024 = 0.5
      else:
        if _tr((1.0 if abs(v_slicer_sub - 2.0) < 0.00001 else 0.0)):
          _t5025 = _div(1.0, 3.0)
        else:
          if _tr((1.0 if abs(v_slicer_sub - 3.0) < 0.00001 else 0.0)):
            _t5026 = 0.25
          else:
            if _tr((1.0 if abs(v_slicer_sub - 4.0) < 0.00001 else 0.0)):
              _t5027 = _div(1.0, 6.0)
            else:
              _t5027 = 0.125
            _t5026 = _t5027
          _t5025 = _t5026
        _t5024 = _t5025
      _t5023 = _t5024
    v_beats_per_step = _t5023
    _t5028 = 1.0 if _tr(v_mclk_on) else 0.0
    if _t5028:
      _t5028 = 1.0 if _tr(v_mclk_valid) else 0.0
    if _tr(_t5028):
      _t5030 = v_tempo
      _t5031 = max(_t5030, 20.0)
      v_mclk_hb = (_div(60.0, _t5031) * v_srate)
      _t5036 = v_mclk_len
      _t5032 = (_div(v_mclk_len, v_mclk_hb) + 0.5)
      _t5033 = _floor(_t5032)
      _t5034 = _t5033
      _t5035 = max(1.0, _t5034)
      v_mclk_hb = _div(_t5036, _t5035)
      _t5037 = (v_mclk_hb * v_beats_per_step)
      _t5038 = max(1.0, _t5037)
      v_samples_per_step = _t5038
      v_clock_abs_pos = ((v_mclk_cyc * v_mclk_len) + v_mclk_pos)
      _t5039 = f_sl_linked()
      if _tr(_t5039):
        _t5042 = v_mclk_hb
        _t5041 = f_grid_beats()
        _t5043 = (_t5042 * _t5041)
        _t5044 = max(1.0, _t5043)
        v_samples_per_step = _t5044
        _t5040 = v_samples_per_step
      else:
        _t5040 = 0.0
      _t5029 = _t5040
    else:
      _t5045 = f_loop_beat_len()
      _t5046 = (_t5045 * v_beats_per_step)
      _t5047 = max(1.0, _t5046)
      v_samples_per_step = _t5047
      v_clock_abs_pos = ((v_clk_cyc * v_length) + v_master_pos)
      _t5048 = f_sl_linked()
      if _tr(_t5048):
        _t5050 = f_loop_beat_len()
        _t5052 = _t5050
        _t5051 = f_grid_beats()
        _t5053 = (_t5052 * _t5051)
        _t5054 = max(1.0, _t5053)
        v_samples_per_step = _t5054
        _t5049 = v_samples_per_step
      else:
        _t5049 = 0.0
      _t5029 = _t5049
    _t5056 = (v_clock_abs_pos + v_delay_len)
    if _tr(v_effective_rev):
      _t5055 = 0.0
    else:
      _t5055 = v_sl_pre_t
    _t5057 = _div((_t5056 + _t5055), v_samples_per_step)
    _t5058 = _floor(_t5057)
    v_current_step_calc = _t5058
    if _tr((0.0 if abs(v_current_step_calc - v_last_slicer_step) < 0.00001 else 1.0)):
      v_last_slicer_step = v_current_step_calc
      v_play_this_slice = 1.0
      if _tr((1.0 if v_dens_occ < 100.0 else 0.0)):
        _t5061 = _rand(1.0)
        v_play_this_slice = (1.0 if _t5061 < (v_dens_occ * 0.01) else 0.0)
        _t5060 = v_play_this_slice
      else:
        _t5060 = 0.0
      if _tr(v_play_this_slice):
        _t5062 = 1.0
      else:
        _t5062 = 0.0
      v_slice_mute_target = _t5062
      _t5063 = (v_srate * 0.003)
      _t5064 = max(2.0, _t5063)
      v_slice_mute_step = _div(1.0, _t5064)
      _t5065 = f_dens_next()
      if _tr((1.0 if abs(v_slicer_mode - 0.0) < 0.00001 else 0.0)):
        _t5067 = v_trans_count
        _t5068 = _rand(_t5067)
        _t5069 = _t5068
        _t5070 = _floor(_t5069)
        v_rnd_idx = _t5070
        v_target_pos = _mget(v_trans_mem + v_rnd_idx)
        _t5071 = f_get_slicer_len()
        _t5072 = _t5071
        _t5073 = _rand(_t5072)
        _t5074 = _t5073
        _t5075 = _floor(_t5074)
        v_rand_pitch_idx = _t5075
        v_p_off = _mget(v_slice_pitch_mem + v_rand_pitch_idx)
        _t5076 = v_target_pos
        _t5077 = v_p_off
        _t5078 = f_slicer_fire(_t5076, _t5077)
        if _tr(v_dub_gran):
          _t5080 = (0.0 if _tr(v_effective_rev) else 1.0)
          _t5081 = f_dub_slice_restart(_t5080)
          _t5079 = _t5081
        else:
          _t5079 = 0.0
        _t5066 = _t5079
      else:
        _t5082 = f_get_slicer_len()
        v_step_len = _t5082
        _t5083 = v_current_step_calc
        _t5084 = abs(_t5083)
        v_target_pos = _mget(v_seq_mem + _mod(_t5084, v_step_len))
        _t5085 = v_current_step_calc
        _t5086 = abs(_t5085)
        v_p_off = _mget(v_slice_pitch_mem + _mod(_t5086, v_step_len))
        _t5087 = v_current_step_calc
        _t5088 = abs(_t5087)
        v_slicer_current_step = _mod((_mod(_t5088, v_step_len) + 1.0), v_step_len)
        _t5089 = v_target_pos
        _t5090 = v_p_off
        _t5091 = f_slicer_fire(_t5089, _t5090)
        if _tr(v_dub_gran):
          _t5093 = (0.0 if _tr(v_effective_rev) else 1.0)
          _t5094 = f_dub_slice_restart(_t5093)
          _t5092 = _t5094
        else:
          _t5092 = 0.0
        _t5066 = _t5092
      _t5059 = _t5066
    else:
      _t5059 = 0.0
    _t5022 = _t5059
  else:
    v_last_slicer_step = (-1.0)
    _t5022 = v_last_slicer_step
  v_slicer_sample_counter = 0.0
  _t5095 = (-v_slice_mute_step)
  _t5096 = v_slice_mute_step
  _t5097 = (v_slice_mute_target - v_slice_mute_gate)
  _t5098 = min(_t5096, _t5097)
  _t5099 = _t5098
  _t5100 = max(_t5095, _t5099)
  v_slice_mute_gate = (v_slice_mute_gate + _t5100)
  _t5101 = 1.0 if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)) else 0.0
  if _t5101:
    _t5101 = 1.0 if _tr((1.0 if v_trans_count > 0.0 else 0.0)) else 0.0
  if _tr(_t5101):
    _t5102 = _pow(2.0, _div(v_current_slice_pitch, 12.0))
  else:
    _t5102 = 1.0
  v_slice_pitch_mult = _t5102
  v_effective_pitch_ratio = (v_pitch_ratio * v_slice_pitch_mult)
  _t5103 = 1.0 if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)) else 0.0
  if _t5103:
    _t5103 = 1.0 if _tr((1.0 if v_trans_count > 0.0 else 0.0)) else 0.0
  if _tr(_t5103):
    _t5105 = (-v_sl_slew)
    _t5106 = v_sl_slew
    _t5107 = (v_sl_run - v_sl_gate)
    _t5108 = min(_t5106, _t5107)
    _t5109 = _t5108
    _t5110 = max(_t5105, _t5109)
    v_sl_gate = (v_sl_gate + _t5110)
    _t5111 = v_sl_gate
    _t5112 = min(1.0, _t5111)
    _t5113 = _t5112
    _t5114 = max(0.0, _t5113)
    v_sl_gate = _t5114
    _t5104 = v_sl_gate
  else:
    v_sl_gate = 1.0
    v_sl_run = 1.0
    _t5104 = v_sl_run
  v_dens_on = (1.0 if v_dens_occ < 99.99 else 0.0)
  if _tr(v_dens_on):
    if _tr((0.0 if abs(v_state - v_dens_prev_state) < 0.00001 else 1.0)):
      v_dens_prev_state = v_state
      v_dens_slot = (-1.0)
      v_dens_seg = 0.0
      v_dens_t = 0.0
      v_dens_ton = 0.0
      v_dens_first = 1.0
      _t5117 = _rand(1.0)
      v_dens_next_on = (1.0 if _t5117 < (v_dens_occ * 0.01) else 0.0)
      _t5116 = v_dens_next_on
    else:
      _t5116 = 0.0
    _t5119 = 1.0 if _tr((1.0 if abs(v_state - 1.0) < 0.00001 else 0.0)) else 0.0
    if not _t5119:
      _t5119 = 1.0 if _tr((1.0 if abs(v_state - 8.0) < 0.00001 else 0.0)) else 0.0
    _t5118 = 1.0 if _tr(_t5119) else 0.0
    if not _t5118:
      _t5122 = 1.0 if _tr((1.0 if v_state >= 3.0 else 0.0)) else 0.0
      if _t5122:
        _t5122 = 1.0 if _tr((1.0 if v_state <= 6.0 else 0.0)) else 0.0
      _t5121 = 1.0 if _tr(_t5122) else 0.0
      if _t5121:
        _t5121 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
      _t5120 = 1.0 if _tr(_t5121) else 0.0
      if _t5120:
        _t5123 = 1.0 if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)) else 0.0
        if _t5123:
          _t5123 = 1.0 if _tr((1.0 if v_trans_count > 0.0 else 0.0)) else 0.0
        _t5120 = 1.0 if _tr((0.0 if _tr(_t5123) else 1.0)) else 0.0
      _t5118 = 1.0 if _tr(_t5120) else 0.0
    if _tr(_t5118):
      v_dens_seg = (v_dens_seg - 1.0)
      if _tr((1.0 if v_dens_seg <= 0.0 else 0.0)):
        _t5126 = f_dens_pick()
        _t5127 = 1.0 if _tr(v_dens_first) else 0.0
        if _t5127:
          _t5128 = 1.0 if _tr((1.0 if abs(v_state - 1.0) < 0.00001 else 0.0)) else 0.0
          if not _t5128:
            _t5128 = 1.0 if _tr((1.0 if abs(v_state - 8.0) < 0.00001 else 0.0)) else 0.0
          _t5127 = 1.0 if _tr(_t5128) else 0.0
        if _tr(_t5127):
          v_dens_g = v_dens_tgt
          _t5129 = v_dens_g
        else:
          _t5129 = 0.0
        v_dens_first = 0.0
        _t5125 = v_dens_first
      else:
        _t5125 = 0.0
      _t5124 = _t5125
    else:
      _t5131 = 1.0 if _tr((1.0 if v_state >= 3.0 else 0.0)) else 0.0
      if _t5131:
        _t5131 = 1.0 if _tr((1.0 if v_state <= 6.0 else 0.0)) else 0.0
      _t5130 = 1.0 if _tr(_t5131) else 0.0
      if _t5130:
        _t5130 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
      if _tr(_t5130):
        if _tr((1.0 if v_dens_slot < 0.0 else 0.0)):
          v_dens_slot = 0.0
          _t5134 = f_dens_next()
          _t5133 = _t5134
        else:
          _t5133 = 0.0
        _t5132 = _t5133
      else:
        _t5132 = 0.0
      _t5124 = _t5132
    _t5135 = (-v_dens_slew)
    _t5136 = v_dens_slew
    _t5137 = (v_dens_tgt - v_dens_g)
    _t5138 = min(_t5136, _t5137)
    _t5139 = _t5138
    _t5140 = max(_t5135, _t5139)
    v_dens_g = (v_dens_g + _t5140)
    _t5115 = v_dens_g
  else:
    v_dens_g = 1.0
    v_dens_prev_state = (-1.0)
    _t5115 = v_dens_prev_state
  if _tr(v_rec_cmd):
    v_rec_cmd = 0.0
    _t5142 = 1.0 if _tr((1.0 if abs(v_state - 1.0) < 0.00001 else 0.0)) else 0.0
    if not _t5142:
      _t5142 = 1.0 if _tr((1.0 if abs(v_state - 8.0) < 0.00001 else 0.0)) else 0.0
    if _tr(_t5142):
      if _tr((1.0 if v_pos > (v_srate * 0.3) else 0.0)):
        v_state_target = 2.0
        v_last_state_target = (-1.0)
        v_rec_stop_lag = v_rec_lag_pend
        _t5144 = v_rec_stop_lag
      else:
        _t5144 = 0.0
      _t5143 = _t5144
    else:
      if _tr((1.0 if abs(v_state - 7.0) < 0.00001 else 0.0)):
        v_state_target = 0.0
        v_last_state_target = (-1.0)
        _t5145 = v_last_state_target
      else:
        if _tr(v_auto_on):
          _t5146 = 7.0
        else:
          _t5146 = 1.0
        v_state_target = _t5146
        v_last_state_target = (-1.0)
        if _tr(v_auto_on):
          _t5147 = 0.0
        else:
          _t5147 = v_rec_lag_pend
        v_rec_start_lag = _t5147
        _t5148 = f_rx_announce()
        _t5145 = _t5148
      _t5143 = _t5145
    v_rec_lag_pend = 0.0
    _t5141 = v_rec_lag_pend
  else:
    _t5141 = 0.0
  if _tr((0.0 if abs(v_xarm - 0.0) < 0.00001 else 1.0)):
    v_xi_s = (v_active_part - 1.0)
    if _tr((1.0 if abs(v_x_mode - 1.0) < 0.00001 else 0.0)):
      v_xph = (v_mclk_pos - v_x_ms)
      v_xper = v_x_per
      _t5150 = v_xper
    else:
      if _tr((1.0 if abs(v_x_mode - 2.0) < 0.00001 else 0.0)):
        v_xph = (v_master_pos - v_x_ms)
        v_xper = v_x_per
        _t5151 = v_xper
      else:
        if _tr((1.0 if abs(v_x_mode - 3.0) < 0.00001 else 0.0)):
          _t5153 = f_ref_host_phase()
          v_xph = (_t5153 - v_x_ms)
          v_xper = v_x_per
          _t5152 = v_xper
        else:
          v_xph = (v_pos - _mget(v_part_sp + v_xi_s))
          v_xper = v_length
          _t5152 = v_xper
        _t5151 = _t5152
      _t5150 = _t5151
    v_x_event = 0.0
    _t5154 = 1.0 if _tr((1.0 if abs(v_x_mode - 0.0) < 0.00001 else 0.0)) else 0.0
    if _t5154:
      _t5154 = 1.0 if _tr((1.0 if _mget(v_part_sp + v_xi_s) < 0.0 else 0.0)) else 0.0
    if _tr(_t5154):
      v_x_event = 1.0
      _t5155 = v_x_event
    else:
      _t5156 = 1.0 if _tr((1.0 if v_xper > 1.0 else 0.0)) else 0.0
      if _t5156:
        _t5157 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
        if not _t5157:
          _t5157 = 1.0 if _tr((1.0 if abs(v_xarm - 4.0) < 0.00001 else 0.0)) else 0.0
        _t5156 = 1.0 if _tr(_t5157) else 0.0
      if _tr(_t5156):
        _t5161 = v_xper
        _t5159 = _div(v_xph, v_xper)
        _t5160 = _floor(_t5159)
        v_xph = (v_xph - (_t5161 * _t5160))
        _t5162 = 1.0 if _tr((1.0 if v_x_ph_prev >= 0.0 else 0.0)) else 0.0
        if _t5162:
          _t5163 = (v_xph - v_x_ph_prev)
          _t5164 = abs(_t5163)
          _t5162 = 1.0 if _tr((1.0 if _t5164 > (v_xper * 0.5) else 0.0)) else 0.0
        if _tr(_t5162):
          v_x_event = 1.0
          _t5165 = v_x_event
        else:
          _t5165 = 0.0
        v_x_ph_prev = v_xph
        _t5158 = v_x_ph_prev
      else:
        _t5158 = 0.0
      _t5155 = _t5158
    if _tr(v_x_event):
      if _tr((1.0 if abs(v_xarm - 1.0) < 0.00001 else 0.0)):
        v_state_target = 0.0
        _t5167 = v_state_target
      else:
        if _tr((1.0 if abs(v_xarm - 4.0) < 0.00001 else 0.0)):
          if _tr(v_x_free):
            v_rec_force_free = 1.0
            _t5169 = v_rec_force_free
          else:
            _t5169 = 0.0
          if _tr(v_auto_on):
            _t5170 = 7.0
          else:
            _t5170 = 1.0
          v_state_target = _t5170
          v_last_state_target = (-1.0)
          _t5168 = v_last_state_target
        else:
          if _tr((1.0 if _mget(v_part_sp + v_xi_s) >= 0.0 else 0.0)):
            _t5172 = _mget(v_part_sp + v_xi_s)
            _t5173 = f_trigger_pos_jump(_t5172)
            _t5174 = (v_length - 1.0)
            _t5175 = _mget(v_part_sp + v_xi_s)
            _t5176 = min(_t5174, _t5175)
            _t5177 = _t5176
            _t5178 = max(0.0, _t5177)
            v_master_pos = _t5178
            _t5171 = v_master_pos
          else:
            _t5171 = 0.0
          if _tr((1.0 if abs(v_xarm - 3.0) < 0.00001 else 0.0)):
            _t5179 = 3.0
          else:
            _t5179 = 2.0
          v_state_target = _t5179
          _t5168 = v_state_target
        _t5167 = _t5168
      v_xarm = 0.0
      _t5166 = v_xarm
    else:
      _t5166 = 0.0
    _t5149 = _t5166
  else:
    _t5149 = 0.0
  if _tr((0.0 if abs(v_state_target - v_last_state_target) < 0.00001 else 1.0)):
    _t5182 = 1.0 if _tr((1.0 if abs(v_state - 3.0) < 0.00001 else 0.0)) else 0.0
    if not _t5182:
      _t5182 = 1.0 if _tr((1.0 if abs(v_state - 4.0) < 0.00001 else 0.0)) else 0.0
    _t5181 = 1.0 if _tr(_t5182) else 0.0
    if not _t5181:
      _t5181 = 1.0 if _tr((1.0 if abs(v_state - 5.0) < 0.00001 else 0.0)) else 0.0
    if _tr(_t5181):
      _t5184 = f_dub_flush()
      _t5183 = _t5184
    else:
      _t5183 = 0.0
    _t5188 = 1.0 if _tr((1.0 if abs(v_state_target - 1.0) < 0.00001 else 0.0)) else 0.0
    if _t5188:
      _t5188 = 1.0 if _tr((0.0 if _tr(v_auto_on) else 1.0)) else 0.0
    _t5187 = 1.0 if _tr(_t5188) else 0.0
    if _t5187:
      _t5187 = 1.0 if _tr((0.0 if abs(v_state - 1.0) < 0.00001 else 1.0)) else 0.0
    _t5186 = 1.0 if _tr(_t5187) else 0.0
    if _t5186:
      _t5186 = 1.0 if _tr((0.0 if abs(v_state - 8.0) < 0.00001 else 1.0)) else 0.0
    _t5185 = 1.0 if _tr(_t5186) else 0.0
    if _t5185:
      _t5185 = 1.0 if _tr((0.0 if abs(v_state - 7.0) < 0.00001 else 1.0)) else 0.0
    if _tr(_t5185):
      _t5190 = f_qs_setup()
      v_qs_wait = _t5190
      v_qs_hit = 0.0
      v_qs_prev = (-1.0)
      if _tr(v_qs_wait):
        v_state_target = 7.0
        _t5191 = v_state_target
      else:
        _t5191 = 0.0
      _t5189 = _t5191
    else:
      _t5189 = 0.0
    if _tr((1.0 if abs(v_state_target - 0.0) < 0.00001 else 0.0)):
      _t5193 = 1.0 if _tr((1.0 if abs(v_state - 1.0) < 0.00001 else 0.0)) else 0.0
      if not _t5193:
        _t5193 = 1.0 if _tr((1.0 if abs(v_state - 8.0) < 0.00001 else 0.0)) else 0.0
      if _tr(_t5193):
        _t5195 = f_finish_rec(0.0)
        _t5194 = _t5195
      else:
        v_pos = 0.0
        v_analysing = 0.0
        _t5194 = v_analysing
      v_state = 0.0
      v_one_shot_playing = 0.0
      v_state_transition_fade = 0.0
      _t5192 = v_state_transition_fade
    else:
      if _tr((1.0 if abs(v_state_target - 1.0) < 0.00001 else 0.0)):
        _t5197 = 1.0 if _tr((1.0 if abs(v_state - 1.0) < 0.00001 else 0.0)) else 0.0
        if not _t5197:
          _t5197 = 1.0 if _tr((1.0 if abs(v_state - 8.0) < 0.00001 else 0.0)) else 0.0
        if _tr(_t5197):
          _t5199 = f_try_finish_rec(2.0, 0.0)
          _t5198 = _t5199
        else:
          v_analysing = 0.0
          v_one_shot_playing = 0.0
          _t5200 = f_switch_history_slot(0.0)
          v_history_head = 0.0
          v_history_count = 1.0
          v_hist_undo = 0.0
          v_hist_redo = 0.0
          v_dirty_len = 0.0
          v_pos = 0.0
          v_master_pos = 0.0
          v_clk_cyc = 0.0
          v_length = 0.0
          v_loop_start = 0.0
          v_loop_width = 0.0
          v_base_loop_length = 0.0
          v_state = 1.0
          v_trans_count = 0.0
          v_state_transition_fade = 0.0
          _t5201 = (v_active_part - 1.0)
          _t5202 = f_sy_clear(_t5201)
          _t5203 = f_rec_ref_capture()
          if _tr((1.0 if v_rec_start_lag > 0.0 else 0.0)):
            _t5205 = v_rec_start_lag
            _t5206 = f_rec_preroll(_t5205)
            _t5204 = _t5206
          else:
            _t5204 = 0.0
          _t5198 = _t5204
        _t5196 = _t5198
      else:
        if _tr((1.0 if abs(v_state_target - 2.0) < 0.00001 else 0.0)):
          _t5208 = 1.0 if _tr((1.0 if abs(v_state - 1.0) < 0.00001 else 0.0)) else 0.0
          if not _t5208:
            _t5208 = 1.0 if _tr((1.0 if abs(v_state - 8.0) < 0.00001 else 0.0)) else 0.0
          if _tr(_t5208):
            _t5210 = f_try_finish_rec(2.0, 0.0)
            _t5209 = _t5210
          else:
            if _tr((1.0 if v_length > 0.0 else 0.0)):
              _t5212 = 1.0 if _tr((1.0 if v_state < 2.0 else 0.0)) else 0.0
              if not _t5212:
                _t5212 = 1.0 if _tr((1.0 if abs(v_state - 7.0) < 0.00001 else 0.0)) else 0.0
              if _tr(_t5212):
                v_state_transition_fade = 0.0
                _t5213 = v_state_transition_fade
              else:
                _t5213 = 0.0
              v_state = 2.0
              _t5211 = v_state
            else:
              _t5211 = 0.0
            _t5209 = _t5211
          _t5207 = _t5209
        else:
          if _tr((1.0 if abs(v_state_target - 3.0) < 0.00001 else 0.0)):
            if _tr((1.0 if abs(v_state - 3.0) < 0.00001 else 0.0)):
              v_state = 2.0
              _t5215 = v_state
            else:
              _t5216 = 1.0 if _tr((1.0 if abs(v_state - 1.0) < 0.00001 else 0.0)) else 0.0
              if not _t5216:
                _t5216 = 1.0 if _tr((1.0 if abs(v_state - 8.0) < 0.00001 else 0.0)) else 0.0
              if _tr(_t5216):
                _t5218 = f_try_finish_rec(3.0, 0.0)
                _t5217 = _t5218
              else:
                _t5219 = f_push_new_history_state()
                v_state = 3.0
                _t5217 = v_state
              _t5220 = _rand(2.0)
              v_dub_pan = (_t5220 - 1.0)
              _t5215 = v_dub_pan
            _t5221 = 1.0 if _tr((0.0 if abs(v_state - 3.0) < 0.00001 else 1.0)) else 0.0
            if _t5221:
              _t5221 = 1.0 if _tr((0.0 if abs(v_state - 8.0) < 0.00001 else 1.0)) else 0.0
            if _tr(_t5221):
              v_state_target = 2.0
              _t5222 = v_state_target
            else:
              _t5222 = 0.0
            _t5214 = _t5222
          else:
            if _tr((1.0 if abs(v_state_target - 4.0) < 0.00001 else 0.0)):
              if _tr((1.0 if abs(v_state - 4.0) < 0.00001 else 0.0)):
                v_state = 2.0
                _t5224 = v_state
              else:
                _t5225 = 1.0 if _tr((1.0 if abs(v_state - 1.0) < 0.00001 else 0.0)) else 0.0
                if not _t5225:
                  _t5225 = 1.0 if _tr((1.0 if abs(v_state - 8.0) < 0.00001 else 0.0)) else 0.0
                if _tr(_t5225):
                  _t5227 = f_try_finish_rec(4.0, 0.0)
                  _t5226 = _t5227
                else:
                  _t5228 = f_push_new_history_state()
                  v_state = 4.0
                  _t5226 = v_state
                _t5229 = _rand(2.0)
                v_dub_pan = (_t5229 - 1.0)
                _t5224 = v_dub_pan
              _t5230 = 1.0 if _tr((0.0 if abs(v_state - 4.0) < 0.00001 else 1.0)) else 0.0
              if _t5230:
                _t5230 = 1.0 if _tr((0.0 if abs(v_state - 8.0) < 0.00001 else 1.0)) else 0.0
              if _tr(_t5230):
                v_state_target = 2.0
                _t5231 = v_state_target
              else:
                _t5231 = 0.0
              _t5223 = _t5231
            else:
              if _tr((1.0 if abs(v_state_target - 5.0) < 0.00001 else 0.0)):
                if _tr((1.0 if abs(v_state - 5.0) < 0.00001 else 0.0)):
                  v_state = 2.0
                  _t5233 = v_state
                else:
                  _t5234 = 1.0 if _tr((1.0 if abs(v_state - 1.0) < 0.00001 else 0.0)) else 0.0
                  if not _t5234:
                    _t5234 = 1.0 if _tr((1.0 if abs(v_state - 8.0) < 0.00001 else 0.0)) else 0.0
                  if _tr(_t5234):
                    _t5236 = f_try_finish_rec(5.0, 0.0)
                    _t5235 = _t5236
                  else:
                    _t5237 = f_push_new_history_state()
                    v_state = 5.0
                    _t5235 = v_state
                  _t5238 = _rand(2.0)
                  v_dub_pan = (_t5238 - 1.0)
                  _t5233 = v_dub_pan
                _t5239 = 1.0 if _tr((0.0 if abs(v_state - 5.0) < 0.00001 else 1.0)) else 0.0
                if _t5239:
                  _t5239 = 1.0 if _tr((0.0 if abs(v_state - 8.0) < 0.00001 else 1.0)) else 0.0
                if _tr(_t5239):
                  v_state_target = 2.0
                  _t5240 = v_state_target
                else:
                  _t5240 = 0.0
                _t5232 = _t5240
              else:
                if _tr((1.0 if abs(v_state_target - 6.0) < 0.00001 else 0.0)):
                  if _tr((1.0 if abs(v_state - 6.0) < 0.00001 else 0.0)):
                    v_state = 2.0
                    _t5242 = v_state
                  else:
                    _t5243 = 1.0 if _tr((1.0 if abs(v_state - 1.0) < 0.00001 else 0.0)) else 0.0
                    if not _t5243:
                      _t5243 = 1.0 if _tr((1.0 if abs(v_state - 8.0) < 0.00001 else 0.0)) else 0.0
                    if _tr(_t5243):
                      _t5245 = f_try_finish_rec(6.0, 0.0)
                      _t5244 = _t5245
                    else:
                      _t5246 = f_push_new_history_state()
                      v_state = 6.0
                      _t5247 = v_base_backup_l
                      _t5248 = v_left_buf
                      _t5249 = v_length
                      _t5250 = _memcpy(_t5247, _t5248, _t5249)
                      _t5251 = v_base_backup_r
                      _t5252 = v_right_buf
                      _t5253 = v_length
                      _t5254 = _memcpy(_t5251, _t5252, _t5253)
                      v_mult_len = v_length
                      _t5244 = v_mult_len
                    _t5255 = _rand(2.0)
                    v_dub_pan = (_t5255 - 1.0)
                    _t5242 = v_dub_pan
                  _t5256 = 1.0 if _tr((0.0 if abs(v_state - 6.0) < 0.00001 else 1.0)) else 0.0
                  if _t5256:
                    _t5256 = 1.0 if _tr((0.0 if abs(v_state - 8.0) < 0.00001 else 1.0)) else 0.0
                  if _tr(_t5256):
                    v_state_target = 2.0
                    _t5257 = v_state_target
                  else:
                    _t5257 = 0.0
                  _t5241 = _t5257
                else:
                  if _tr((1.0 if abs(v_state_target - 7.0) < 0.00001 else 0.0)):
                    _t5259 = 1.0 if _tr((1.0 if abs(v_state - 1.0) < 0.00001 else 0.0)) else 0.0
                    if not _t5259:
                      _t5259 = 1.0 if _tr((1.0 if abs(v_state - 8.0) < 0.00001 else 0.0)) else 0.0
                    if _tr(_t5259):
                      _t5261 = f_try_finish_rec(2.0, 0.0)
                      _t5260 = _t5261
                    else:
                      v_analysing = 0.0
                      v_one_shot_playing = 0.0
                      _t5262 = f_switch_history_slot(0.0)
                      v_history_head = 0.0
                      v_history_count = 1.0
                      v_hist_undo = 0.0
                      v_hist_redo = 0.0
                      v_dirty_len = 0.0
                      v_pos = 0.0
                      v_master_pos = 0.0
                      v_clk_cyc = 0.0
                      v_length = 0.0
                      v_loop_start = 0.0
                      v_loop_width = 0.0
                      v_base_loop_length = 0.0
                      v_state = 7.0
                      v_trans_count = 0.0
                      v_state_transition_fade = 0.0
                      _t5263 = (v_active_part - 1.0)
                      _t5264 = f_sy_clear(_t5263)
                      _t5260 = _t5264
                    _t5258 = _t5260
                  else:
                    _t5258 = 0.0
                  _t5241 = _t5258
                _t5232 = _t5241
              _t5223 = _t5232
            _t5214 = _t5223
          _t5207 = _t5214
        _t5196 = _t5207
      _t5192 = _t5196
    v_last_state_target = v_state_target
    v_rec_start_lag = 0.0
    v_rec_stop_lag = 0.0
    _t5180 = v_rec_stop_lag
  else:
    _t5180 = 0.0
  if _tr((1.0 if v_state < 2.0 else 0.0)):
    v_prev_normal_playback = 0.0
    _t5265 = v_prev_normal_playback
  else:
    _t5265 = 0.0
  if _tr((0.0 if abs(v_state - 7.0) < 0.00001 else 1.0)):
    v_qs_wait = 0.0
    _t5266 = v_qs_wait
  else:
    _t5266 = 0.0
  if _tr((1.0 if abs(v_state - 0.0) < 0.00001 else 0.0)):
    v_wet_s0 = 0.0
    v_wet_s1 = 0.0
    _t5268 = (v_replace_fade - v_replace_fade_coeff)
    _t5269 = max(0.0, _t5268)
    v_replace_fade = _t5269
    _t5267 = v_replace_fade
  else:
    if _tr((1.0 if abs(v_state - 7.0) < 0.00001 else 0.0)):
      v_wet_s0 = 0.0
      v_wet_s1 = 0.0
      _t5271 = (v_replace_fade - v_replace_fade_coeff)
      _t5272 = max(0.0, _t5271)
      v_replace_fade = _t5272
      _t5274 = 1.0 if _tr(v_qs_wait) else 0.0
      if _t5274:
        _t5274 = 1.0 if _tr((0.0 if _tr(v_auto_on) else 1.0)) else 0.0
      _t5273 = 1.0 if _tr(_t5274) else 0.0
      if _t5273:
        _t5273 = 1.0 if _tr((0.0 if _tr(v_qs_hit) else 1.0)) else 0.0
      if _tr(_t5273):
        _t5276 = f_qs_check()
        _t5275 = _t5276
      else:
        _t5275 = 0.0
      _t5279 = 1.0 if _tr((0.0 if _tr(v_qs_wait) else 1.0)) else 0.0
      if not _t5279:
        _t5279 = 1.0 if _tr(v_auto_on) else 0.0
      _t5278 = 1.0 if _tr(_t5279) else 0.0
      if not _t5278:
        _t5278 = 1.0 if _tr(v_qs_hit) else 0.0
      _t5277 = 1.0 if _tr(_t5278) else 0.0
      if _t5277:
        _t5280 = 1.0 if _tr((0.0 if _tr(v_auto_on) else 1.0)) else 0.0
        if not _t5280:
          _t5280 = 1.0 if _tr((1.0 if v_curr_peak > v_trans_sens else 0.0)) else 0.0
        _t5277 = 1.0 if _tr(_t5280) else 0.0
      if _tr(_t5277):
        _t5283 = 1.0 if _tr(v_qs_wait) else 0.0
        if _t5283:
          _t5283 = 1.0 if _tr((0.0 if _tr(v_auto_on) else 1.0)) else 0.0
        _t5282 = 1.0 if _tr(_t5283) else 0.0
        if _t5282:
          _t5282 = 1.0 if _tr(v_qs_hit) else 0.0
        v_qs_snap = _t5282
        v_qs_wait = 0.0
        v_state = 1.0
        v_state_target = 1.0
        v_last_state_target = 1.0
        _t5284 = f_rec_ref_capture()
        if _tr(v_qs_snap):
          _t5286 = f_rec_ref_snap()
          _t5285 = _t5286
        else:
          _t5285 = 0.0
        _t5287 = _time()
        v_rec_start_time = _t5287
        v_old_pos = v_pos
        v_pos = (v_pos + v_rec_speed)
        _t5288 = v_dirty_len
        _t5289 = v_pos
        _t5290 = max(_t5288, _t5289)
        v_dirty_len = _t5290
        _t5291 = v_old_pos
        _t5292 = v_pos
        _t5293 = f_tape_write_span(_t5291, _t5292, 1.0)
        _t5281 = _t5293
      else:
        _t5281 = 0.0
      _t5270 = _t5281
    else:
      if _tr((1.0 if abs(v_state - 1.0) < 0.00001 else 0.0)):
        v_old_pos = v_pos
        v_pos = (v_pos + v_rec_speed)
        _t5295 = v_dirty_len
        _t5296 = v_pos
        _t5297 = max(_t5295, _t5296)
        v_dirty_len = _t5297
        if _tr((1.0 if v_pos >= v_buf_len else 0.0)):
          _t5299 = v_old_pos
          _t5300 = (v_buf_len - 0.0001)
          _t5301 = f_tape_write_span(_t5299, _t5300, 1.0)
          v_pos = v_buf_len
          _t5302 = f_try_finish_rec(2.0, 0.0)
          v_state_target = 2.0
          _t5298 = v_state_target
        else:
          _t5303 = v_old_pos
          _t5304 = v_pos
          _t5305 = f_tape_write_span(_t5303, _t5304, 1.0)
          _t5298 = _t5305
        v_wet_s0 = 0.0
        v_wet_s1 = 0.0
        _t5306 = (v_replace_fade - v_replace_fade_coeff)
        _t5307 = max(0.0, _t5306)
        v_replace_fade = _t5307
        _t5294 = v_replace_fade
      else:
        if _tr((1.0 if abs(v_state - 8.0) < 0.00001 else 0.0)):
          v_old_pos = v_pos
          v_pos = (v_pos + v_rec_speed)
          _t5309 = v_dirty_len
          _t5310 = v_pos
          _t5311 = max(_t5309, _t5310)
          v_dirty_len = _t5311
          if _tr((1.0 if v_pos >= v_target_sync_len else 0.0)):
            _t5313 = v_old_pos
            _t5314 = (v_target_sync_len - 0.0001)
            _t5315 = f_tape_write_span(_t5313, _t5314, 1.0)
            v_co_p = (v_pos - v_target_sync_len)
            v_pos = v_target_sync_len
            _t5316 = v_pending_next_state
            _t5317 = f_finish_rec(_t5316)
            v_state_target = v_pending_next_state
            v_last_state_target = v_pending_next_state
            if _tr(v_co_rec):
              _t5319 = v_co_p
              _t5320 = max(0.0, _t5319)
              v_co_p = _t5320
              _t5323 = v_length
              _t5321 = _div(v_co_p, v_length)
              _t5322 = _floor(_t5321)
              v_co_p = (v_co_p - (_t5323 * _t5322))
              v_pos = v_co_p
              v_master_pos = v_co_p
              if _tr((1.0 if abs(v_active_part - 1.0) < 0.00001 else 0.0)):
                v_master_pos1 = v_co_p
                _t5324 = v_master_pos1
              else:
                if _tr((1.0 if abs(v_active_part - 2.0) < 0.00001 else 0.0)):
                  v_master_pos2 = v_co_p
                  _t5325 = v_master_pos2
                else:
                  v_master_pos3 = v_co_p
                  _t5325 = v_master_pos3
                _t5324 = _t5325
              v_co_rec = 0.0
              _t5318 = v_co_rec
            else:
              _t5318 = 0.0
            _t5312 = _t5318
          else:
            _t5326 = v_old_pos
            _t5327 = v_pos
            _t5328 = f_tape_write_span(_t5326, _t5327, 1.0)
            _t5312 = _t5328
          v_wet_s0 = 0.0
          v_wet_s1 = 0.0
          _t5329 = (v_replace_fade - v_replace_fade_coeff)
          _t5330 = max(0.0, _t5329)
          v_replace_fade = _t5330
          _t5308 = v_replace_fade
        else:
          _t5331 = 1.0 if _tr((1.0 if v_state >= 2.0 else 0.0)) else 0.0
          if _t5331:
            _t5331 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
          if _tr(_t5331):
            if _tr(v_link_eff):
              _t5333 = v_varispeed
            else:
              _t5333 = v_sm_speed
            v_rate_t = _t5333
            if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)):
              _t5334 = v_slice_pitch_mult
            else:
              _t5334 = 1.0
            v_rate_t = (v_rate_t * _t5334)
            _t5335 = 1.0 if _tr((1.0 if v_degradation > 0.0001 else 0.0)) else 0.0
            if _t5335:
              _t5336 = (v_feedback - 1.0)
              _t5337 = abs(_t5336)
              _t5335 = 1.0 if _tr((1.0 if _t5337 > 0.001 else 0.0)) else 0.0
            if _tr(_t5335):
              v_wow_phase = (v_wow_phase + _div(0.5, v_srate))
              if _tr((1.0 if v_wow_phase >= 1.0 else 0.0)):
                v_wow_phase = (v_wow_phase - 1.0)
                _t5339 = v_wow_phase
              else:
                _t5339 = 0.0
              v_flutter_phase = (v_flutter_phase + _div(6.0, v_srate))
              if _tr((1.0 if v_flutter_phase >= 1.0 else 0.0)):
                v_flutter_phase = (v_flutter_phase - 1.0)
                _t5340 = v_flutter_phase
              else:
                _t5340 = 0.0
              _t5341 = ((2.0 * 3.141592653589793) * v_wow_phase)
              _t5342 = math.sin(_t5341)
              v_wow_mod = (_t5342 * (v_degradation * 0.003))
              _t5343 = ((2.0 * 3.141592653589793) * v_flutter_phase)
              _t5344 = math.sin(_t5343)
              v_flutter_mod = (_t5344 * (v_degradation * 0.001))
              _t5338 = v_flutter_mod
            else:
              _t5338 = 0.0
            _t5345 = (v_length - v_clk_len_ref)
            _t5346 = abs(_t5345)
            if _tr((1.0 if _t5346 > 0.5 else 0.0)):
              v_clk_len_ref = v_length
              v_sync_hard_resync = 1.0
              v_sync_c_w = (-1.0)
              v_sync_c_l = (-1.0)
              _t5347 = v_sync_c_l
            else:
              _t5347 = 0.0
            _t5349 = (v_sm_speed - v_prev_sm_speed)
            _t5350 = abs(_t5349)
            _t5348 = 1.0 if _tr((1.0 if _t5350 > 5e-05 else 0.0)) else 0.0
            if not _t5348:
              _t5351 = (v_pitch_ratio - v_prev_pitch_ratio_sig)
              _t5352 = abs(_t5351)
              _t5348 = 1.0 if _tr((1.0 if _t5352 > 5e-05 else 0.0)) else 0.0
            if _tr(_t5348):
              v_prev_sm_speed = v_sm_speed
              v_prev_pitch_ratio_sig = v_pitch_ratio
              v_sync_hard_resync = 1.0
              _t5353 = v_sync_hard_resync
            else:
              _t5353 = 0.0
            _t5355 = (v_loop_start - v_prev_loop_start)
            _t5356 = abs(_t5355)
            _t5354 = 1.0 if _tr((1.0 if _t5356 > 0.5 else 0.0)) else 0.0
            if not _t5354:
              _t5357 = (v_loop_width - v_prev_loop_width)
              _t5358 = abs(_t5357)
              _t5354 = 1.0 if _tr((1.0 if _t5358 > 0.5 else 0.0)) else 0.0
            if _tr(_t5354):
              v_prev_loop_start = v_loop_start
              v_prev_loop_width = v_loop_width
              v_sync_hard_resync = 1.0
              _t5359 = v_sync_hard_resync
            else:
              _t5359 = 0.0
            _t5360 = 1.0 if _tr((0.0 if abs(v_rev_on - v_prev_rev_on) < 0.00001 else 1.0)) else 0.0
            if not _t5360:
              _t5360 = 1.0 if _tr((0.0 if abs(v_pingpong_on - v_prev_pingpong_on) < 0.00001 else 1.0)) else 0.0
            if _tr(_t5360):
              v_prev_pingpong_on = v_pingpong_on
              v_sync_hard_resync = 1.0
              _t5361 = v_sync_hard_resync
            else:
              _t5361 = 0.0
            v_play_mode_changed = (0.0 if abs(v_play_mode - v_prev_play_mode) < 0.00001 else 1.0)
            _t5362 = 1.0 if _tr((1.0 if abs(v_prev_play_mode - 1.0) < 0.00001 else 0.0)) else 0.0
            if _t5362:
              _t5362 = 1.0 if _tr((1.0 if abs(v_play_mode - 0.0) < 0.00001 else 0.0)) else 0.0
            v_leave_slicer = _t5362
            _t5363 = 1.0 if _tr((1.0 if abs(v_prev_play_mode - 2.0) < 0.00001 else 0.0)) else 0.0
            if _t5363:
              _t5363 = 1.0 if _tr((1.0 if abs(v_play_mode - 0.0) < 0.00001 else 0.0)) else 0.0
            v_leave_oneshot = _t5363
            _t5365 = 1.0 if _tr(v_leave_slicer) else 0.0
            if not _t5365:
              _t5365 = 1.0 if _tr(v_leave_oneshot) else 0.0
            _t5364 = 1.0 if _tr(_t5365) else 0.0
            if not _t5364:
              _t5364 = 1.0 if _tr(v_play_mode_changed) else 0.0
            if _tr(_t5364):
              v_sync_hard_resync = 1.0
              _t5366 = v_sync_hard_resync
            else:
              _t5366 = 0.0
            if _tr(v_leave_slicer):
              _t5368 = v_xf_len_jump
              _t5369 = f_xf_begin(_t5368, 1.0)
              _t5367 = _t5369
            else:
              if _tr(v_play_mode_changed):
                v_pd_arm = 1.0
                _t5370 = v_pd_arm
              else:
                _t5370 = 0.0
              _t5367 = _t5370
            _t5371 = 1.0 if _tr((1.0 if v_prev_state_for_sync < 2.0 else 0.0)) else 0.0
            if _t5371:
              _t5371 = 1.0 if _tr((1.0 if v_state >= 2.0 else 0.0)) else 0.0
            v_leave_stop = _t5371
            if _tr(v_leave_stop):
              v_sync_hard_resync = 1.0
              _t5372 = v_sync_hard_resync
            else:
              _t5372 = 0.0
            _t5375 = (v_loop_width - v_sync_c_w)
            _t5376 = abs(_t5375)
            _t5374 = 1.0 if _tr((1.0 if _t5376 > 0.01 else 0.0)) else 0.0
            if not _t5374:
              _t5377 = (v_length - v_sync_c_l)
              _t5378 = abs(_t5377)
              _t5374 = 1.0 if _tr((1.0 if _t5378 > 0.01 else 0.0)) else 0.0
            _t5373 = 1.0 if _tr(_t5374) else 0.0
            if not _t5373:
              _t5379 = (v_rate_t - v_sync_c_r)
              _t5380 = abs(_t5379)
              _t5373 = 1.0 if _tr((1.0 if _t5380 > 1e-09 else 0.0)) else 0.0
            if _tr(_t5373):
              v_sync_c_w = v_loop_width
              v_sync_c_l = v_length
              v_sync_c_r = v_rate_t
              _t5382 = f_sync_eval()
              _t5381 = _t5382
            else:
              _t5381 = 0.0
            _t5384 = 1.0 if _tr(v_prev_cloud_on) else 0.0
            if _t5384:
              _t5384 = 1.0 if _tr((0.0 if _tr(v_cloud_on) else 1.0)) else 0.0
            _t5383 = 1.0 if _tr(_t5384) else 0.0
            if _t5383:
              _t5383 = 1.0 if _tr((1.0 if abs(v_sync_a - 0.0) < 0.00001 else 0.0)) else 0.0
            if _tr(_t5383):
              _t5386 = v_master_pos
              _t5387 = f_trigger_pos_jump(_t5386)
              _t5385 = _t5387
            else:
              _t5385 = 0.0
            v_prev_cloud_on = v_cloud_on
            _t5391 = 1.0 if _tr((1.0 if abs(v_play_mode - 0.0) < 0.00001 else 0.0)) else 0.0
            if _t5391:
              _t5391 = 1.0 if _tr((0.0 if _tr(v_is_one_shot_mode) else 1.0)) else 0.0
            _t5390 = 1.0 if _tr(_t5391) else 0.0
            if _t5390:
              _t5390 = 1.0 if _tr((1.0 if v_sync_a > 0.0 else 0.0)) else 0.0
            _t5389 = 1.0 if _tr(_t5390) else 0.0
            if _t5389:
              _t5392 = 1.0 if _tr((0.0 if abs(v_state - 6.0) < 0.00001 else 1.0)) else 0.0
              if not _t5392:
                _t5393 = 1.0 if _tr((1.0 if abs(v_sync_a - 1.0) < 0.00001 else 0.0)) else 0.0
                if _t5393:
                  _t5393 = 1.0 if _tr((1.0 if abs(v_sync_b - 1.0) < 0.00001 else 0.0)) else 0.0
                _t5392 = 1.0 if _tr(_t5393) else 0.0
              _t5389 = 1.0 if _tr(_t5392) else 0.0
            _t5388 = 1.0 if _tr(_t5389) else 0.0
            if _t5388:
              _t5394 = 1.0 if _tr((1.0 if abs(v_sync_a - 1.0) < 0.00001 else 0.0)) else 0.0
              if not _t5394:
                _t5394 = 1.0 if _tr((0.0 if _tr(v_pingpong_on) else 1.0)) else 0.0
              _t5388 = 1.0 if _tr(_t5394) else 0.0
            v_is_normal_playback = _t5388
            v_sync_key = ((v_sync_a * 16.0) + v_sync_b)
            v_rev_changed = (0.0 if abs(v_rev_on - v_prev_rev_on) < 0.00001 else 1.0)
            _t5397 = 1.0 if _tr(v_rev_changed) else 0.0
            if not _t5397:
              _t5397 = 1.0 if _tr(v_leave_slicer) else 0.0
            _t5396 = 1.0 if _tr(_t5397) else 0.0
            if not _t5396:
              _t5396 = 1.0 if _tr(v_leave_oneshot) else 0.0
            _t5395 = 1.0 if _tr(_t5396) else 0.0
            if not _t5395:
              _t5395 = 1.0 if _tr(v_leave_stop) else 0.0
            v_force_mode_exit = _t5395
            _t5398 = 1.0 if _tr(v_is_normal_playback) else 0.0
            if _t5398:
              _t5401 = 1.0 if _tr((0.0 if _tr(v_prev_normal_playback) else 1.0)) else 0.0
              if not _t5401:
                _t5401 = 1.0 if _tr(v_force_mode_exit) else 0.0
              _t5400 = 1.0 if _tr(_t5401) else 0.0
              if not _t5400:
                _t5400 = 1.0 if _tr((0.0 if abs(v_sync_key - v_prev_sync_key) < 0.00001 else 1.0)) else 0.0
              _t5399 = 1.0 if _tr(_t5400) else 0.0
              if not _t5399:
                _t5399 = 1.0 if _tr(v_sync_hard_resync) else 0.0
              _t5398 = 1.0 if _tr(_t5399) else 0.0
            v_need_resync = _t5398
            _t5402 = 1.0 if _tr(v_need_resync) else 0.0
            if not _t5402:
              _t5406 = 1.0 if _tr(v_force_mode_exit) else 0.0
              if _t5406:
                _t5406 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
              _t5405 = 1.0 if _tr(_t5406) else 0.0
              if _t5405:
                _t5405 = 1.0 if _tr((1.0 if v_loop_width > 0.0 else 0.0)) else 0.0
              _t5404 = 1.0 if _tr(_t5405) else 0.0
              if _t5404:
                _t5404 = 1.0 if _tr((1.0 if abs(v_play_mode - 0.0) < 0.00001 else 0.0)) else 0.0
              _t5403 = 1.0 if _tr(_t5404) else 0.0
              if _t5403:
                _t5403 = 1.0 if _tr((0.0 if _tr(v_is_one_shot_mode) else 1.0)) else 0.0
              _t5402 = 1.0 if _tr(_t5403) else 0.0
            if _tr(_t5402):
              _t5408 = f_sync_expected()
              v_rs_to = _t5408
              _t5409 = (v_rs_to - v_pos)
              _t5410 = abs(_t5409)
              if _tr((1.0 if _t5410 > 64.0 else 0.0)):
                _t5412 = v_xf_len_rs
                _t5413 = f_xf_begin(_t5412, 1.0)
                _t5411 = _t5413
              else:
                _t5414 = (v_rs_to - v_pos)
                _t5415 = abs(_t5414)
                if _tr((1.0 if _t5415 > 0.5 else 0.0)):
                  v_pd_arm = 1.0
                  _t5416 = v_pd_arm
                else:
                  _t5416 = 0.0
                _t5411 = _t5416
              _t5417 = v_rs_to
              _t5418 = f_trigger_pos_jump(_t5417)
              v_sync_hard_resync = 0.0
              _t5407 = v_sync_hard_resync
            else:
              _t5419 = 1.0 if _tr(v_is_normal_playback) else 0.0
              if _t5419:
                _t5419 = 1.0 if _tr(v_wrapped) else 0.0
              if _tr(_t5419):
                _t5421 = f_sync_expected()
                v_sync_exp = _t5421
                v_sync_dev = (v_pos - v_sync_exp)
                _t5424 = v_loop_width
                _t5422 = (_div(v_sync_dev, v_loop_width) + 0.5)
                _t5423 = _floor(_t5422)
                v_sync_dev = (v_sync_dev - (_t5424 * _t5423))
                _t5425 = v_sync_dev
                _t5426 = abs(_t5425)
                if _tr((1.0 if _t5426 > 1.0 else 0.0)):
                  _t5428 = v_sync_dev
                  _t5429 = abs(_t5428)
                  if _tr((1.0 if _t5429 > 64.0 else 0.0)):
                    _t5431 = v_xf_len_rs
                    _t5432 = f_xf_begin(_t5431, 1.0)
                    _t5430 = _t5432
                  else:
                    v_pd_arm = 1.0
                    _t5430 = v_pd_arm
                  _t5433 = v_sync_exp
                  _t5434 = f_trigger_pos_jump(_t5433)
                  _t5427 = _t5434
                else:
                  _t5427 = 0.0
                _t5420 = _t5427
              else:
                _t5420 = 0.0
              _t5407 = _t5420
            v_prev_normal_playback = v_is_normal_playback
            v_prev_sync_key = v_sync_key
            v_prev_rev_on = v_rev_on
            v_prev_play_mode = v_play_mode
            v_prev_state_for_sync = v_state
            v_smooth_start = ((v_smooth_start * v_param_smooth_coeff) + (v_loop_start * (1.0 - v_param_smooth_coeff)))
            v_smooth_width = ((v_smooth_width * v_param_smooth_coeff) + (v_loop_width * (1.0 - v_param_smooth_coeff)))
            v_eff_start = v_smooth_start
            v_eff_end = (v_smooth_start + v_smooth_width)
            if _tr((1.0 if v_eff_end > v_length else 0.0)):
              v_eff_end = v_length
              _t5435 = v_eff_end
            else:
              _t5435 = 0.0
            if _tr((1.0 if v_eff_end < v_eff_start else 0.0)):
              v_eff_end = v_eff_start
              _t5436 = v_eff_end
            else:
              _t5436 = 0.0
            _t5437 = (v_eff_end - v_eff_start)
            _t5438 = max(_t5437, 16.0)
            v_eff_len = _t5438
            _t5440 = v_rev_on
            _t5439 = 1.0 if _tr(v_pingpong_on) else 0.0
            if _t5439:
              _t5439 = 1.0 if _tr((1.0 if v_ping_pong_dir < 0.0 else 0.0)) else 0.0
            v_effective_rev = (0.0 if abs(_t5440 - _t5439) < 0.00001 else 1.0)
            _t5444 = 1.0 if _tr((1.0 if abs(v_state - 6.0) < 0.00001 else 0.0)) else 0.0
            if _t5444:
              _t5444 = 1.0 if _tr((1.0 if v_mult_len > 256.0 else 0.0)) else 0.0
            _t5443 = 1.0 if _tr(_t5444) else 0.0
            if _t5443:
              _t5443 = 1.0 if _tr((1.0 if v_loop_start < 1.0 else 0.0)) else 0.0
            _t5442 = 1.0 if _tr(_t5443) else 0.0
            if _t5442:
              _t5442 = 1.0 if _tr((1.0 if (v_loop_start + v_loop_width) >= (v_length - 1.0) else 0.0)) else 0.0
            _t5441 = 1.0 if _tr(_t5442) else 0.0
            if _t5441:
              _t5441 = 1.0 if _tr((1.0 if (v_length + v_mult_len) <= v_buf_len else 0.0)) else 0.0
            v_ml_ok = _t5441
            _t5445 = 1.0 if _tr(v_ml_ok) else 0.0
            if _t5445:
              _t5445 = 1.0 if _tr((0.0 if _tr(v_effective_rev) else 1.0)) else 0.0
            v_ml_fwd_free = _t5445
            _t5448 = v_pos
            _t5447 = v_delay_len
            if _tr(v_effective_rev):
              _t5446 = (-1.0)
            else:
              _t5446 = 1.0
            v_safe_pos = (_t5448 + (_t5447 * _t5446))
            if _tr((1.0 if v_safe_pos >= v_eff_end else 0.0)):
              v_safe_pos = (v_safe_pos - v_eff_len)
              _t5449 = v_safe_pos
            else:
              _t5449 = 0.0
            if _tr((1.0 if v_safe_pos < v_eff_start else 0.0)):
              v_safe_pos = (v_safe_pos + v_eff_len)
              _t5450 = v_safe_pos
            else:
              _t5450 = 0.0
            _t5451 = v_safe_pos
            _t5452 = _floor(_t5451)
            v_p1 = _t5452
            if _tr((1.0 if v_p1 < v_eff_start else 0.0)):
              v_p1 = v_eff_start
              _t5453 = v_p1
            else:
              _t5453 = 0.0
            if _tr((1.0 if v_p1 >= v_eff_end else 0.0)):
              v_p1 = (v_eff_end - 1.0)
              _t5454 = v_p1
            else:
              _t5454 = 0.0
            v_frac = (v_safe_pos - v_p1)
            v_p0 = (v_p1 - 1.0)
            if _tr((1.0 if v_p0 < v_eff_start else 0.0)):
              v_p0 = (v_p0 + v_eff_len)
              _t5455 = v_p0
            else:
              _t5455 = 0.0
            v_p2 = (v_p1 + 1.0)
            if _tr((1.0 if v_p2 >= v_eff_end else 0.0)):
              v_p2 = (v_p2 - v_eff_len)
              _t5456 = v_p2
            else:
              _t5456 = 0.0
            v_p3 = (v_p2 + 1.0)
            if _tr((1.0 if v_p3 >= v_eff_end else 0.0)):
              v_p3 = (v_p3 - v_eff_len)
              _t5457 = v_p3
            else:
              _t5457 = 0.0
            _t5458 = v_frac
            _t5459 = _mget(v_left_buf + v_p0)
            _t5460 = _mget(v_left_buf + v_p1)
            _t5461 = _mget(v_left_buf + v_p2)
            _t5462 = _mget(v_left_buf + v_p3)
            _t5463 = f_hermite(_t5458, _t5459, _t5460, _t5461, _t5462)
            v_s0_safe = _t5463
            _t5464 = v_frac
            _t5465 = _mget(v_right_buf + v_p0)
            _t5466 = _mget(v_right_buf + v_p1)
            _t5467 = _mget(v_right_buf + v_p2)
            _t5468 = _mget(v_right_buf + v_p3)
            _t5469 = f_hermite(_t5464, _t5465, _t5466, _t5467, _t5468)
            v_s1_safe = _t5469
            if _tr(v_xfade_pos_active):
              _t5473 = v_old_pos_ptr
              _t5472 = v_delay_len
              if _tr(v_effective_rev):
                _t5471 = (-1.0)
              else:
                _t5471 = 1.0
              v_old_safe_pos = (_t5473 + (_t5472 * _t5471))
              if _tr((1.0 if v_old_safe_pos >= v_eff_end else 0.0)):
                v_old_safe_pos = (v_old_safe_pos - v_eff_len)
                _t5474 = v_old_safe_pos
              else:
                _t5474 = 0.0
              if _tr((1.0 if v_old_safe_pos < v_eff_start else 0.0)):
                v_old_safe_pos = (v_old_safe_pos + v_eff_len)
                _t5475 = v_old_safe_pos
              else:
                _t5475 = 0.0
              _t5476 = v_old_safe_pos
              _t5477 = _floor(_t5476)
              v_op1 = _t5477
              if _tr((1.0 if v_op1 < v_eff_start else 0.0)):
                v_op1 = v_eff_start
                _t5478 = v_op1
              else:
                _t5478 = 0.0
              if _tr((1.0 if v_op1 >= v_eff_end else 0.0)):
                v_op1 = (v_eff_end - 1.0)
                _t5479 = v_op1
              else:
                _t5479 = 0.0
              v_ofrac = (v_old_safe_pos - v_op1)
              v_op0 = (v_op1 - 1.0)
              if _tr((1.0 if v_op0 < v_eff_start else 0.0)):
                v_op0 = (v_op0 + v_eff_len)
                _t5480 = v_op0
              else:
                _t5480 = 0.0
              v_op2 = (v_op1 + 1.0)
              if _tr((1.0 if v_op2 >= v_eff_end else 0.0)):
                v_op2 = (v_op2 - v_eff_len)
                _t5481 = v_op2
              else:
                _t5481 = 0.0
              v_op3 = (v_op2 + 1.0)
              if _tr((1.0 if v_op3 >= v_eff_end else 0.0)):
                v_op3 = (v_op3 - v_eff_len)
                _t5482 = v_op3
              else:
                _t5482 = 0.0
              _t5483 = v_ofrac
              _t5484 = _mget(v_left_buf + v_op0)
              _t5485 = _mget(v_left_buf + v_op1)
              _t5486 = _mget(v_left_buf + v_op2)
              _t5487 = _mget(v_left_buf + v_op3)
              _t5488 = f_hermite(_t5483, _t5484, _t5485, _t5486, _t5487)
              v_old_s0 = _t5488
              _t5489 = v_ofrac
              _t5490 = _mget(v_right_buf + v_op0)
              _t5491 = _mget(v_right_buf + v_op1)
              _t5492 = _mget(v_right_buf + v_op2)
              _t5493 = _mget(v_right_buf + v_op3)
              _t5494 = f_hermite(_t5489, _t5490, _t5491, _t5492, _t5493)
              v_old_s1 = _t5494
              v_xfade_gain = _div(v_xfade_pos_count, v_xfade_pos_len)
              v_s0_safe = ((v_old_s0 * (1.0 - v_xfade_gain)) + (v_s0_safe * v_xfade_gain))
              v_s1_safe = ((v_old_s1 * (1.0 - v_xfade_gain)) + (v_s1_safe * v_xfade_gain))
              _t5496 = v_pos_step
              if _tr(v_effective_rev):
                _t5495 = (-1.0)
              else:
                _t5495 = 1.0
              v_old_pos_ptr = (v_old_pos_ptr + (_t5496 * _t5495))
              if _tr((1.0 if v_old_pos_ptr < v_eff_start else 0.0)):
                v_old_pos_ptr = (v_old_pos_ptr + v_eff_len)
                _t5497 = v_old_pos_ptr
              else:
                if _tr((1.0 if v_old_pos_ptr >= v_eff_end else 0.0)):
                  v_old_pos_ptr = (v_old_pos_ptr - v_eff_len)
                  _t5498 = v_old_pos_ptr
                else:
                  _t5498 = 0.0
                _t5497 = _t5498
              v_xfade_pos_count = (v_xfade_pos_count + 1.0)
              if _tr((1.0 if v_xfade_pos_count >= v_xfade_pos_len else 0.0)):
                v_xfade_pos_active = 0.0
                _t5499 = v_xfade_pos_active
              else:
                _t5499 = 0.0
              _t5470 = _t5499
            else:
              _t5470 = 0.0
            if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)):
              if _tr((1.0 if v_slice_hold > 0.0 else 0.0)):
                v_slice_hold = (v_slice_hold - 1.0)
                _t5501 = v_slice_hold
              else:
                _t5502 = (v_slice_env - v_slice_decay_step)
                _t5503 = max(0.0, _t5502)
                v_slice_env = _t5503
                _t5504 = (v_slice_att + v_slice_att_step)
                _t5505 = min(1.0, _t5504)
                v_slice_att = _t5505
                _t5501 = v_slice_att
              v_g_main = (((v_slice_env * v_slice_att) * v_sl_gate) * v_slice_mute_gate)
              _t5500 = v_g_main
            else:
              v_slice_env = 1.0
              v_g_main = 1.0
              _t5500 = v_g_main
            _t5506 = v_fade_ms
            if _tr(v_br_on):
              _t5507 = 3.0
            else:
              _t5507 = 0.0
            _t5508 = _t5507
            _t5509 = max(_t5506, _t5508)
            _t5510 = ((_t5509 * 0.001) * v_srate)
            _t5511 = (v_eff_len * 0.5)
            _t5512 = min(_t5510, _t5511)
            v_fade_samps = _t5512
            v_rel_pos = (v_safe_pos - v_eff_start)
            v_loop_envelope = 1.0
            if _tr((0.0 if abs(v_play_mode - 1.0) < 0.00001 else 1.0)):
              _t5514 = 1.0 if _tr((1.0 if v_fade_samps > 0.0 else 0.0)) else 0.0
              if _t5514:
                _t5514 = 1.0 if _tr((1.0 if v_rel_pos < v_fade_samps else 0.0)) else 0.0
              if _tr(_t5514):
                _t5516 = v_loop_envelope
                _t5517 = _div(v_rel_pos, v_fade_samps)
                _t5518 = min(_t5516, _t5517)
                v_loop_envelope = _t5518
                _t5515 = v_loop_envelope
              else:
                _t5515 = 0.0
              v_dist_from_end = (v_eff_end - v_safe_pos)
              _t5520 = 1.0 if _tr((1.0 if v_fade_samps > 0.0 else 0.0)) else 0.0
              if _t5520:
                _t5520 = 1.0 if _tr((1.0 if v_dist_from_end < v_fade_samps else 0.0)) else 0.0
              _t5519 = 1.0 if _tr(_t5520) else 0.0
              if _t5519:
                _t5519 = 1.0 if _tr((0.0 if _tr(v_ml_fwd_free) else 1.0)) else 0.0
              if _tr(_t5519):
                _t5522 = v_loop_envelope
                _t5523 = _div(v_dist_from_end, v_fade_samps)
                _t5524 = min(_t5522, _t5523)
                v_loop_envelope = _t5524
                _t5521 = v_loop_envelope
              else:
                _t5521 = 0.0
              _t5513 = _t5521
            else:
              _t5513 = 0.0
            v_g_main = (v_g_main * v_loop_envelope)
            v_s0_safe = (v_s0_safe * v_g_main)
            v_s1_safe = (v_s1_safe * v_g_main)
            if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)):
              _t5525 = v_stereo_width
            else:
              _t5525 = 0.0
            v_sl_pan_amt = (v_sl_pan_amt + ((_t5525 - v_sl_pan_amt) * v_sl_pan_k))
            if _tr((1.0 if v_sl_pan_amt > 0.0001 else 0.0)):
              _t5527 = v_s0_safe
              _t5528 = v_s1_safe
              _t5529 = v_slice_pan
              _t5530 = v_sl_pan_amt
              _t5531 = f_pan_lr(_t5527, _t5528, _t5529, _t5530)
              v_s0_safe = v_pan_ol
              v_s1_safe = v_pan_or
              _t5526 = v_s1_safe
            else:
              _t5526 = 0.0
            v_rd_last_l = v_left_buf
            v_rd_last_r = v_right_buf
            v_rd_last_p = v_safe_pos
            v_rd_last_ws = v_eff_start
            v_rd_last_we = v_eff_end
            v_rd_last_g = v_g_main
            v_rd_last_pan = v_slice_pan
            v_rd_last_pamt = v_sl_pan_amt
            v_rd_valid = 1.0
            if _tr(v_xf_on):
              v_xf_w = (v_xf_we - v_xf_ws)
              if _tr((1.0 if v_xf_w >= 2.0 else 0.0)):
                v_xp = (v_xf_p - v_xf_ws)
                _t5534 = _div(v_xp, v_xf_w)
                _t5535 = _floor(_t5534)
                v_xp = (v_xp - (_t5535 * v_xf_w))
                v_xp = (v_xp + v_xf_ws)
                _t5536 = v_xp
                _t5537 = _floor(_t5536)
                v_xq1 = _t5537
                v_xfr = (v_xp - v_xq1)
                if _tr((1.0 if v_xq1 >= v_xf_we else 0.0)):
                  v_xq1 = (v_xq1 - v_xf_w)
                  _t5538 = v_xq1
                else:
                  _t5538 = 0.0
                v_xq0 = (v_xq1 - 1.0)
                if _tr((1.0 if v_xq0 < v_xf_ws else 0.0)):
                  v_xq0 = (v_xq0 + v_xf_w)
                  _t5539 = v_xq0
                else:
                  _t5539 = 0.0
                v_xq2 = (v_xq1 + 1.0)
                if _tr((1.0 if v_xq2 >= v_xf_we else 0.0)):
                  v_xq2 = (v_xq2 - v_xf_w)
                  _t5540 = v_xq2
                else:
                  _t5540 = 0.0
                v_xq3 = (v_xq2 + 1.0)
                if _tr((1.0 if v_xq3 >= v_xf_we else 0.0)):
                  v_xq3 = (v_xq3 - v_xf_w)
                  _t5541 = v_xq3
                else:
                  _t5541 = 0.0
                _t5542 = v_xq0
                _t5543 = _floor(_t5542)
                v_xq0 = _t5543
                _t5544 = v_xq1
                _t5545 = _floor(_t5544)
                v_xq1 = _t5545
                _t5546 = v_xq2
                _t5547 = _floor(_t5546)
                v_xq2 = _t5547
                _t5548 = v_xq3
                _t5549 = _floor(_t5548)
                v_xq3 = _t5549
                _t5550 = v_xfr
                _t5551 = _mget(v_xf_l + v_xq0)
                _t5552 = _mget(v_xf_l + v_xq1)
                _t5553 = _mget(v_xf_l + v_xq2)
                _t5554 = _mget(v_xf_l + v_xq3)
                _t5555 = f_hermite(_t5550, _t5551, _t5552, _t5553, _t5554)
                v_gh_l = (_t5555 * v_xf_g)
                _t5556 = v_xfr
                _t5557 = _mget(v_xf_r + v_xq0)
                _t5558 = _mget(v_xf_r + v_xq1)
                _t5559 = _mget(v_xf_r + v_xq2)
                _t5560 = _mget(v_xf_r + v_xq3)
                _t5561 = f_hermite(_t5556, _t5557, _t5558, _t5559, _t5560)
                v_gh_r = (_t5561 * v_xf_g)
                if _tr((1.0 if v_xf_pamt > 0.0001 else 0.0)):
                  _t5563 = v_gh_l
                  _t5564 = v_gh_r
                  _t5565 = v_xf_pan
                  _t5566 = v_xf_pamt
                  _t5567 = f_pan_lr(_t5563, _t5564, _t5565, _t5566)
                  v_gh_l = v_pan_ol
                  v_gh_r = v_pan_or
                  _t5562 = v_gh_r
                else:
                  _t5562 = 0.0
                _t5533 = _t5562
              else:
                v_gh_l = 0.0
                v_gh_r = 0.0
                _t5533 = v_gh_r
              if _tr(v_xf_eqp):
                _t5569 = ((v_xf_k * 3.141592653589793) * 0.5)
                _t5570 = math.sin(_t5569)
                v_xa = _t5570
                _t5571 = ((v_xf_k * 3.141592653589793) * 0.5)
                _t5572 = math.cos(_t5571)
                v_xb = _t5572
                _t5568 = v_xb
              else:
                _t5573 = (v_xf_k * 3.141592653589793)
                _t5574 = math.cos(_t5573)
                v_xa = (0.5 - (0.5 * _t5574))
                v_xb = (1.0 - v_xa)
                _t5568 = v_xb
              v_s0_safe = ((v_s0_safe * v_xa) + (v_gh_l * v_xb))
              v_s1_safe = ((v_s1_safe * v_xa) + (v_gh_r * v_xb))
              v_xf_p = (v_xf_p + v_xf_st)
              v_xf_k = (v_xf_k + v_xf_inc)
              if _tr((1.0 if v_xf_k >= 1.0 else 0.0)):
                v_xf_on = 0.0
                _t5575 = v_xf_on
              else:
                _t5575 = 0.0
              _t5532 = _t5575
            else:
              _t5532 = 0.0
            if _tr(v_pd_arm):
              v_pd_l = (v_pd_prev_l - v_s0_safe)
              v_pd_r = (v_pd_prev_r - v_s1_safe)
              v_pd_arm = 0.0
              _t5576 = v_pd_arm
            else:
              _t5576 = 0.0
            _t5577 = 1.0 if _tr((0.0 if abs(v_pd_l - 0.0) < 0.00001 else 1.0)) else 0.0
            if not _t5577:
              _t5577 = 1.0 if _tr((0.0 if abs(v_pd_r - 0.0) < 0.00001 else 1.0)) else 0.0
            if _tr(_t5577):
              v_s0_safe = (v_s0_safe + v_pd_l)
              v_s1_safe = (v_s1_safe + v_pd_r)
              v_pd_l = (v_pd_l * v_pd_k)
              v_pd_r = (v_pd_r * v_pd_k)
              _t5579 = v_pd_l
              _t5580 = abs(_t5579)
              _t5583 = _t5580
              _t5581 = v_pd_r
              _t5582 = abs(_t5581)
              if _tr((1.0 if (_t5583 + _t5582) < 1e-07 else 0.0)):
                v_pd_l = 0.0
                v_pd_r = 0.0
                _t5584 = v_pd_r
              else:
                _t5584 = 0.0
              _t5578 = _t5584
            else:
              _t5578 = 0.0
            v_pd_prev_l = v_s0_safe
            v_pd_prev_r = v_s1_safe
            _t5585 = _ix(v_delay_buf_l + v_delay_idx)
            _t5586 = v_s0_safe
            _mset(_t5585, _t5586)
            _t5587 = _ix(v_delay_buf_r + v_delay_idx)
            _t5588 = v_s1_safe
            _mset(_t5587, _t5588)
            v_read_idx = (v_delay_idx + 1.0)
            if _tr((1.0 if v_read_idx >= v_delay_len else 0.0)):
              v_read_idx = 0.0
              _t5589 = v_read_idx
            else:
              _t5589 = 0.0
            v_s0 = _mget(v_delay_buf_l + v_read_idx)
            v_s1 = _mget(v_delay_buf_r + v_read_idx)
            v_delay_idx = (v_delay_idx + 1.0)
            if _tr((1.0 if v_delay_idx >= v_delay_len else 0.0)):
              v_delay_idx = 0.0
              _t5590 = v_delay_idx
            else:
              _t5590 = 0.0
            _t5591 = 1.0 if _tr((0.0 if _tr(v_link_eff) else 1.0)) else 0.0
            if _t5591:
              _t5593 = (v_sm_speed - 1.0)
              _t5594 = abs(_t5593)
              _t5592 = 1.0 if _tr((1.0 if _t5594 > 0.0005 else 0.0)) else 0.0
              if not _t5592:
                _t5595 = v_sm_pitch
                _t5596 = abs(_t5595)
                _t5592 = 1.0 if _tr((1.0 if _t5596 > 0.005 else 0.0)) else 0.0
              _t5591 = 1.0 if _tr(_t5592) else 0.0
            v_gran_now = _t5591
            _t5599 = 1.0 if _tr((1.0 if abs(v_state - 3.0) < 0.00001 else 0.0)) else 0.0
            if not _t5599:
              _t5599 = 1.0 if _tr((1.0 if abs(v_state - 4.0) < 0.00001 else 0.0)) else 0.0
            _t5598 = 1.0 if _tr(_t5599) else 0.0
            if not _t5598:
              _t5598 = 1.0 if _tr((1.0 if abs(v_state - 5.0) < 0.00001 else 0.0)) else 0.0
            _t5597 = 1.0 if _tr(_t5598) else 0.0
            if not _t5597:
              _t5597 = 1.0 if _tr((1.0 if abs(v_state - 6.0) < 0.00001 else 0.0)) else 0.0
            v_is_dubbing = _t5597
            _t5601 = 1.0 if _tr(v_acc_ok) else 0.0
            if _t5601:
              _t5601 = 1.0 if _tr(v_gran_now) else 0.0
            _t5600 = 1.0 if _tr(_t5601) else 0.0
            if _t5600:
              _t5603 = 1.0 if _tr((1.0 if abs(v_state - 3.0) < 0.00001 else 0.0)) else 0.0
              if not _t5603:
                _t5603 = 1.0 if _tr((1.0 if abs(v_state - 4.0) < 0.00001 else 0.0)) else 0.0
              _t5602 = 1.0 if _tr(_t5603) else 0.0
              if not _t5602:
                _t5602 = 1.0 if _tr((1.0 if abs(v_state - 5.0) < 0.00001 else 0.0)) else 0.0
              _t5600 = 1.0 if _tr(_t5602) else 0.0
            v_dub_gran = _t5600
            _t5604 = 1.0 if _tr(v_dub_gran_prev) else 0.0
            if _t5604:
              _t5604 = 1.0 if _tr((0.0 if _tr(v_dub_gran) else 1.0)) else 0.0
            if _tr(_t5604):
              _t5606 = f_dub_flush()
              _t5605 = _t5606
            else:
              _t5605 = 0.0
            v_dub_gran_prev = v_dub_gran
            if _tr((0.0 if abs(v_state - 5.0) < 0.00001 else 1.0)):
              v_auto_rep_active = 0.0
              v_auto_rep_hold_counter = 0.0
              v_input_env = 0.0
              v_auto_above_prev = 0.0
              v_ar_in = 0.0
              v_ar_lp = 0.0
              v_ar_cnt = 0.0
              _t5607 = v_ar_cnt
            else:
              _t5607 = 0.0
            v_is_recording = v_is_dubbing
            if _tr(v_link_eff):
              _t5610 = v_varispeed
              if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)):
                _t5609 = v_slice_pitch_mult
              else:
                _t5609 = 1.0
              v_pos_step = (_t5610 * _t5609)
              v_grain_target = 0.0
              _t5608 = v_grain_target
            else:
              _t5612 = v_sm_speed
              if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)):
                _t5611 = v_slice_pitch_mult
              else:
                _t5611 = 1.0
              v_pos_step = (_t5612 * _t5611)
              if _tr(v_gran_now):
                _t5613 = 1.0
              else:
                _t5613 = 0.0
              v_grain_target = _t5613
              _t5608 = v_grain_target
            if _tr((0.0 if abs(v_grain_target - v_grain_mix) < 0.00001 else 1.0)):
              if _tr((1.0 if v_grain_target > v_grain_mix else 0.0)):
                _t5615 = 1.0
              else:
                _t5615 = (-1.0)
              v_grain_mix = (v_grain_mix + (_t5615 * v_xfade_coeff))
              if _tr((1.0 if v_grain_mix < 0.0 else 0.0)):
                v_grain_mix = 0.0
                _t5616 = v_grain_mix
              else:
                if _tr((1.0 if v_grain_mix > 1.0 else 0.0)):
                  v_grain_mix = 1.0
                  _t5617 = v_grain_mix
                else:
                  _t5617 = 0.0
                _t5616 = _t5617
              _t5614 = _t5616
            else:
              _t5614 = 0.0
            _t5619 = 1.0 if _tr((1.0 if v_grain_mix > 0.001 else 0.0)) else 0.0
            if _t5619:
              _t5619 = 1.0 if _tr((0.0 if abs(v_play_mode - 1.0) < 0.00001 else 1.0)) else 0.0
            _t5618 = 1.0 if _tr(_t5619) else 0.0
            if _t5618:
              _t5620 = 1.0 if _tr((0.0 if _tr(v_is_one_shot_mode) else 1.0)) else 0.0
              if not _t5620:
                _t5620 = 1.0 if _tr(v_one_shot_playing) else 0.0
              _t5618 = 1.0 if _tr(_t5620) else 0.0
            if _tr(_t5618):
              if _tr(0.0):
                v_d_norm = v_cloud_density
                v_c_factor = v_cloud_chaos
                v_target_grain_ms = (2.0 + (_pow(v_d_norm, 2.0) * 798.0))
                v_grain_dur = ((v_srate * v_target_grain_ms) * 0.001)
                v_base_gt_ms = (28.0 + ((1.0 - v_d_norm) * 52.0))
                _t5623 = _rand(2.0)
                v_rnd_factor = ((_t5623 - 1.0) * v_c_factor)
                _t5624 = (v_base_gt_ms + (v_rnd_factor * 26.0))
                _t5625 = max(28.0, _t5624)
                v_target_gt_ms = _t5625
                if _tr((1.0 if v_d_norm > 0.5 else 0.0)):
                  v_num_active_voices = (1.0 + (((v_d_norm - 0.5) * 2.0) * 15.0))
                  _t5627 = v_target_gt_ms
                  _t5628 = _div(v_target_grain_ms, v_num_active_voices)
                  _t5629 = min(_t5627, _t5628)
                  v_target_gt_ms = _t5629
                  _t5626 = v_target_gt_ms
                else:
                  _t5626 = 0.0
                v_gt = ((v_srate * v_target_gt_ms) * 0.001)
                _t5630 = 1.0 if _tr((1.0 if v_cloud_lfo_rate > 0.001 else 0.0)) else 0.0
                if _t5630:
                  _t5630 = 1.0 if _tr((1.0 if v_cloud_lfo_depth > 0.001 else 0.0)) else 0.0
                if _tr(_t5630):
                  v_cloud_lfo_phase = (v_cloud_lfo_phase + _div(v_cloud_lfo_rate, v_srate))
                  if _tr((1.0 if v_cloud_lfo_phase >= 1.0 else 0.0)):
                    v_cloud_lfo_phase = (v_cloud_lfo_phase - 1.0)
                    _t5632 = v_cloud_lfo_phase
                  else:
                    _t5632 = 0.0
                  _t5631 = _t5632
                else:
                  _t5631 = 0.0
                if _tr((1.0 if abs(v_cloud_lfo_shape - 0.0) < 0.00001 else 0.0)):
                  _t5634 = ((2.0 * 3.141592653589793) * v_cloud_lfo_phase)
                  _t5635 = math.sin(_t5634)
                  _t5633 = _t5635
                else:
                  if _tr((1.0 if abs(v_cloud_lfo_shape - 1.0) < 0.00001 else 0.0)):
                    _t5636 = ((v_cloud_lfo_phase * 2.0) - 1.0)
                  else:
                    _t5636 = (1.0 - (v_cloud_lfo_phase * 2.0))
                  _t5633 = _t5636
                v_lfo_val = _t5633
                if _tr((1.0 if abs(v_cloud_pos_mode - 0.0) < 0.00001 else 0.0)):
                  _t5637 = v_pos
                else:
                  _t5637 = (v_eff_start + ((v_cloud_pos_pct * 0.01) * v_eff_len))
                v_base_cloud_center = _t5637
                v_lfo_offset = (((v_lfo_val * (v_cloud_lfo_depth * 0.01)) * v_eff_len) * 0.5)
                v_cloud_center = (v_base_cloud_center + v_lfo_offset)
                v_cloud_center_draw = v_cloud_center
                _t5622 = v_cloud_center_draw
              else:
                v_grain_dur = ((v_srate * v_grain_ms) * 0.001)
                _t5640 = (v_grain_dur * v_effective_pitch_ratio)
                _t5638 = v_pos_step
                _t5639 = max(_t5638, 0.0001)
                v_gt = _div(_t5640, _t5639)
                _t5641 = v_gt
                _t5642 = (v_grain_dur * 0.5)
                _t5643 = min(_t5641, _t5642)
                _t5644 = _t5643
                _t5645 = (v_grain_dur * 0.15)
                _t5646 = max(_t5644, _t5645)
                v_gt = _t5646
                _t5622 = v_gt
              v_spawn_timer = (v_spawn_timer + 1.0)
              if _tr((1.0 if v_spawn_timer >= v_gt else 0.0)):
                v_spawn_timer = 0.0
                v_gi = 0.0
                for _t5648 in range(max(0, int(v_max_grains))):
                  v_g_base = (v_grain_mem + (v_gi * v_grain_data_size))
                  if _tr((1.0 if abs(_mget(v_g_base + 2.0) - 0.0) < 0.00001 else 0.0)):
                    if _tr(0.0):
                      _t5651 = _rand(2.0)
                      v_spread_offset = ((_t5651 - 1.0) * ((v_cloud_spread * v_eff_len) * 0.5))
                      v_spawn_target_pos = (v_cloud_center + v_spread_offset)
                      if _tr((1.0 if v_c_factor > 0.001 else 0.0)):
                        _t5653 = _rand(2.0)
                        v_spawn_target_pos = (v_spawn_target_pos + ((_t5653 - 1.0) * (((v_cloud_spread * v_eff_len) * 0.5) * v_c_factor)))
                        _t5652 = v_spawn_target_pos
                      else:
                        _t5652 = 0.0
                      v_spawn_target_pos = (v_spawn_target_pos - v_eff_start)
                      _t5654 = _div(v_spawn_target_pos, v_eff_len)
                      _t5655 = _floor(_t5654)
                      v_spawn_target_pos = (v_spawn_target_pos - (_t5655 * v_eff_len))
                      v_spawn_target_pos = (v_spawn_target_pos + v_eff_start)
                      _t5656 = _ix(v_g_base + 0.0)
                      _t5657 = v_spawn_target_pos
                      _mset(_t5656, _t5657)
                      _t5658 = _ix(v_g_base + 1.0)
                      _t5659 = 0.0
                      _mset(_t5658, _t5659)
                      _t5660 = _ix(v_g_base + 2.0)
                      _t5661 = 1.0
                      _mset(_t5660, _t5661)
                      _t5662 = _ix(v_g_base + 3.0)
                      _t5663 = v_grain_dur
                      _mset(_t5662, _t5663)
                      _t5664 = _ix(v_g_base + 4.0)
                      _t5665 = _rand(2.0)
                      _t5666 = ((_t5665 - 1.0) * v_stereo_width)
                      _mset(_t5664, _t5666)
                      _t5667 = _ix(v_g_base + 5.0)
                      _t5668 = v_cloud_density
                      _mset(_t5667, _t5668)
                      _t5669 = _ix(v_g_base + 6.0)
                      _t5670 = v_spawn_target_pos
                      _mset(_t5669, _t5670)
                      _t5671 = _ix(v_g_base + 7.0)
                      _t5672 = v_cloud_pitch_spread
                      _t5673 = f_calc_cloud_pitch(_t5672)
                      _t5674 = _t5673
                      _mset(_t5671, _t5674)
                      _t5650 = _t5674
                    else:
                      v_rd_dl = 0.0
                      _t5675 = (((v_read_align_ms * 0.001) * v_srate) + 0.5)
                      _t5676 = _floor(_t5675)
                      v_rd_sn = _t5676
                      _t5677 = (0.4 * v_grain_dur)
                      _t5678 = _floor(_t5677)
                      _t5679 = _t5678
                      _t5680 = min(512.0, _t5679)
                      v_rd_wn = _t5680
                      _t5682 = 1.0 if _tr((1.0 if v_rd_sn > 0.0 else 0.0)) else 0.0
                      if _t5682:
                        _t5682 = 1.0 if _tr((1.0 if v_rd_wn >= 64.0 else 0.0)) else 0.0
                      _t5681 = 1.0 if _tr(_t5682) else 0.0
                      if _t5681:
                        _t5681 = 1.0 if _tr(v_rd_prev_ok) else 0.0
                      if _tr(_t5681):
                        v_rd_ph = (v_ih_n - v_rd_prev_n)
                        _t5684 = 1.0 if _tr((1.0 if v_rd_ph > 0.0 else 0.0)) else 0.0
                        if _t5684:
                          _t5684 = 1.0 if _tr((1.0 if (v_rd_ph + v_rd_wn) < v_rd_prev_dur else 0.0)) else 0.0
                        if _tr(_t5684):
                          _t5686 = v_pos
                          _t5687 = v_rd_prev_start
                          _t5688 = v_rd_ph
                          _t5689 = v_rd_sn
                          _t5690 = v_rd_wn
                          _t5691 = v_effective_pitch_ratio
                          if _tr(v_effective_rev):
                            _t5692 = (-1.0)
                          else:
                            _t5692 = 1.0
                          _t5693 = _t5692
                          _t5694 = f_rd_pick(_t5686, _t5687, _t5688, _t5689, _t5690, _t5691, _t5693)
                          v_rd_dl = _t5694
                          _t5685 = v_rd_dl
                        else:
                          _t5685 = 0.0
                        _t5683 = _t5685
                      else:
                        _t5683 = 0.0
                      _t5695 = _ix(v_g_base + 0.0)
                      _t5696 = (v_pos + v_rd_dl)
                      _mset(_t5695, _t5696)
                      _t5697 = _ix(v_g_base + 1.0)
                      _t5698 = 0.0
                      _mset(_t5697, _t5698)
                      _t5699 = _ix(v_g_base + 2.0)
                      _t5700 = 1.0
                      _mset(_t5699, _t5700)
                      _t5701 = _ix(v_g_base + 3.0)
                      _t5702 = v_grain_dur
                      _mset(_t5701, _t5702)
                      _t5703 = _ix(v_g_base + 4.0)
                      _t5704 = 0.0
                      _mset(_t5703, _t5704)
                      _t5705 = _ix(v_g_base + 5.0)
                      _t5706 = 0.0
                      _mset(_t5705, _t5706)
                      _t5707 = _ix(v_g_base + 6.0)
                      _t5708 = v_pos
                      _mset(_t5707, _t5708)
                      _t5709 = _ix(v_g_base + 7.0)
                      _t5710 = 0.0
                      _mset(_t5709, _t5710)
                      v_rd_prev_start = _mget(v_g_base + 0.0)
                      v_rd_prev_n = v_ih_n
                      v_rd_prev_dur = v_grain_dur
                      v_rd_prev_ok = 1.0
                      _t5650 = v_rd_prev_ok
                    v_gi = v_max_grains
                    _t5649 = v_gi
                  else:
                    _t5649 = 0.0
                  v_gi = (v_gi + 1.0)
                _t5647 = 0.0
              else:
                _t5647 = 0.0
              v_granular_l = 0.0
              v_granular_r = 0.0
              v_total_w = 0.0
              v_gi = 0.0
              if _tr(v_effective_rev):
                _t5711 = (-1.0)
              else:
                _t5711 = 1.0
              v_g_dir = _t5711
              for _t5712 in range(max(0, int(v_max_grains))):
                v_g_base = (v_grain_mem + (v_gi * v_grain_data_size))
                if _tr((1.0 if abs(_mget(v_g_base + 2.0) - 1.0) < 0.00001 else 0.0)):
                  v_g_phase = _mget(v_g_base + 1.0)
                  v_g_dur = _mget(v_g_base + 3.0)
                  v_g_pan = _mget(v_g_base + 4.0)
                  v_g_dens = _mget(v_g_base + 5.0)
                  v_g_pitch_off = _mget(v_g_base + 7.0)
                  if _tr((1.0 if v_g_phase >= v_g_dur else 0.0)):
                    _t5715 = _ix(v_g_base + 2.0)
                    _t5716 = 0.0
                    _mset(_t5715, _t5716)
                    _t5714 = _t5716
                  else:
                    _t5714 = 0.0
                  v_grain_pitch_mult = 1.0
                  v_rd_f = (_mget(v_g_base + 0.0) + (((v_g_phase * v_effective_pitch_ratio) * v_grain_pitch_mult) * v_g_dir))
                  v_rd_f = (v_rd_f - v_eff_start)
                  _t5717 = _div(v_rd_f, v_eff_len)
                  _t5718 = _floor(_t5717)
                  v_rd_f = (v_rd_f - (_t5718 * v_eff_len))
                  v_rd_f = (v_rd_f + v_eff_start)
                  _t5719 = v_eff_start
                  _t5720 = (v_eff_end - 1.0001)
                  _t5721 = v_rd_f
                  _t5722 = min(_t5720, _t5721)
                  _t5723 = _t5722
                  _t5724 = max(_t5719, _t5723)
                  v_rd_f = _t5724
                  _t5725 = v_rd_f
                  _t5726 = _floor(_t5725)
                  v_rd_i = _t5726
                  v_rd_frac = (v_rd_f - v_rd_i)
                  v_rp1 = v_rd_i
                  _t5727 = v_eff_start
                  _t5728 = (v_rp1 - 1.0)
                  _t5729 = max(_t5727, _t5728)
                  v_rp0 = _t5729
                  _t5730 = (v_eff_end - 1.0)
                  _t5731 = (v_rp1 + 1.0)
                  _t5732 = min(_t5730, _t5731)
                  v_rp2 = _t5732
                  _t5733 = (v_eff_end - 1.0)
                  _t5734 = (v_rp2 + 1.0)
                  _t5735 = min(_t5733, _t5734)
                  v_rp3 = _t5735
                  v_p_norm = _div(v_g_phase, v_g_dur)
                  v_min_fade_samps = (v_srate * 0.0015)
                  _t5736 = v_min_fade_samps
                  _t5737 = (v_g_dur * (0.02 + (v_g_dens * 0.48)))
                  _t5738 = max(_t5736, _t5737)
                  v_f_samps = _t5738
                  v_env = 1.0
                  v_curr_samp = v_g_phase
                  if _tr((1.0 if v_curr_samp < v_f_samps else 0.0)):
                    v_env = _div(v_curr_samp, v_f_samps)
                    _t5739 = v_env
                  else:
                    if _tr((1.0 if (v_g_dur - v_curr_samp) < v_f_samps else 0.0)):
                      v_env = _div((v_g_dur - v_curr_samp), v_f_samps)
                      _t5740 = v_env
                    else:
                      _t5740 = 0.0
                    _t5739 = _t5740
                  _t5741 = v_env
                  _t5742 = min(1.0, _t5741)
                  _t5743 = _t5742
                  _t5744 = max(0.0, _t5743)
                  v_env = _t5744
                  _t5745 = (v_env * 3.141592653589793)
                  _t5746 = math.cos(_t5745)
                  v_env = (0.5 - (0.5 * _t5746))
                  _t5747 = v_rd_frac
                  _t5748 = _mget(v_left_buf + v_rp0)
                  _t5749 = _mget(v_left_buf + v_rp1)
                  _t5750 = _mget(v_left_buf + v_rp2)
                  _t5751 = _mget(v_left_buf + v_rp3)
                  _t5752 = f_hermite(_t5747, _t5748, _t5749, _t5750, _t5751)
                  v_g_l = (_t5752 * v_env)
                  _t5753 = v_rd_frac
                  _t5754 = _mget(v_right_buf + v_rp0)
                  _t5755 = _mget(v_right_buf + v_rp1)
                  _t5756 = _mget(v_right_buf + v_rp2)
                  _t5757 = _mget(v_right_buf + v_rp3)
                  _t5758 = f_hermite(_t5753, _t5754, _t5755, _t5756, _t5757)
                  v_g_r = (_t5758 * v_env)
                  if _tr(0.0):
                    v_p_ang = (((v_g_pan + 1.0) * 0.25) * 3.141592653589793)
                    _t5760 = v_p_ang
                    _t5761 = math.cos(_t5760)
                    v_gl_gain = (_t5761 * 1.414)
                    _t5762 = v_p_ang
                    _t5763 = math.sin(_t5762)
                    v_gr_gain = (_t5763 * 1.414)
                    v_g_mono = ((v_g_l + v_g_r) * 0.5)
                    v_g_l = (v_g_mono * v_gl_gain)
                    v_g_r = (v_g_mono * v_gr_gain)
                    _t5759 = v_g_r
                  else:
                    _t5759 = 0.0
                  v_granular_l = (v_granular_l + v_g_l)
                  v_granular_r = (v_granular_r + v_g_r)
                  v_total_w = (v_total_w + v_env)
                  _t5764 = _ix(v_g_base + 1.0)
                  _t5765 = (v_g_phase + 1.0)
                  _mset(_t5764, _t5765)
                  _t5713 = _t5765
                else:
                  _t5713 = 0.0
                v_gi = (v_gi + 1.0)
              if _tr((1.0 if v_total_w < 0.001 else 0.0)):
                v_total_w = 0.001
                _t5766 = v_total_w
              else:
                _t5766 = 0.0
              v_loop_env_pos = 1.0
              _t5767 = 1.0 if _tr((1.0 if v_fade_samps > 0.0 else 0.0)) else 0.0
              if _t5767:
                _t5767 = 1.0 if _tr((1.0 if (v_pos - v_eff_start) < v_fade_samps else 0.0)) else 0.0
              if _tr(_t5767):
                _t5769 = v_loop_env_pos
                _t5770 = _div((v_pos - v_eff_start), v_fade_samps)
                _t5771 = min(_t5769, _t5770)
                v_loop_env_pos = _t5771
                _t5768 = v_loop_env_pos
              else:
                _t5768 = 0.0
              _t5773 = 1.0 if _tr((1.0 if v_fade_samps > 0.0 else 0.0)) else 0.0
              if _t5773:
                _t5773 = 1.0 if _tr((1.0 if (v_eff_end - v_pos) < v_fade_samps else 0.0)) else 0.0
              _t5772 = 1.0 if _tr(_t5773) else 0.0
              if _t5772:
                _t5772 = 1.0 if _tr((0.0 if _tr(v_ml_fwd_free) else 1.0)) else 0.0
              if _tr(_t5772):
                _t5775 = v_loop_env_pos
                _t5776 = _div((v_eff_end - v_pos), v_fade_samps)
                _t5777 = min(_t5775, _t5776)
                v_loop_env_pos = _t5777
                _t5774 = v_loop_env_pos
              else:
                _t5774 = 0.0
              if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)):
                _t5778 = (((v_slice_env * v_slice_att) * v_sl_gate) * v_slice_mute_gate)
              else:
                _t5778 = 1.0
              v_slice_g = _t5778
              v_base_mix_factor = v_grain_mix
              v_s0 = ((v_s0 * (1.0 - v_base_mix_factor)) + (((_div(v_granular_l, v_total_w) * v_loop_env_pos) * v_slice_g) * v_base_mix_factor))
              v_s1 = ((v_s1 * (1.0 - v_base_mix_factor)) + (((_div(v_granular_r, v_total_w) * v_loop_env_pos) * v_slice_g) * v_base_mix_factor))
              _t5621 = v_s1
            else:
              _t5621 = 0.0
            if _tr(v_cloud_on):
              _t5780 = (v_cloud_x + _div(1.0, (v_srate * 0.015)))
              _t5781 = min(1.0, _t5780)
              _t5779 = _t5781
            else:
              _t5782 = (v_cloud_x - _div(1.0, (v_srate * 0.015)))
              _t5783 = max(0.0, _t5782)
              _t5779 = _t5783
            v_cloud_x = _t5779
            _t5785 = 1.0 if _tr((1.0 if v_cloud_x > 0.0001 else 0.0)) else 0.0
            if _t5785:
              _t5785 = 1.0 if _tr((0.0 if abs(v_play_mode - 1.0) < 0.00001 else 1.0)) else 0.0
            _t5784 = 1.0 if _tr(_t5785) else 0.0
            if _t5784:
              _t5786 = 1.0 if _tr((0.0 if _tr(v_is_one_shot_mode) else 1.0)) else 0.0
              if not _t5786:
                _t5786 = 1.0 if _tr(v_one_shot_playing) else 0.0
              _t5784 = 1.0 if _tr(_t5786) else 0.0
            if _tr(_t5784):
              _t5788 = 1.0 if _tr(v_cl_snap) else 0.0
              if _t5788:
                _t5788 = 1.0 if _tr((1.0 if v_eff_len > 16.0 else 0.0)) else 0.0
              if _tr(_t5788):
                _t5790 = (_div((v_pos - v_eff_start), v_eff_len) * 100.0)
                _t5791 = min(100.0, _t5790)
                _t5792 = _t5791
                _t5793 = max(0.0, _t5792)
                v_cloud_pos_pct = _t5793
                v_cloud_pos_pct = v_cloud_pos_pct
                v_cl_snap = 0.0
                _t5789 = v_cl_snap
              else:
                _t5789 = 0.0
              _t5794 = v_cloud_chaos
              _t5795 = min(1.0, _t5794)
              _t5796 = _t5795
              _t5797 = max(0.0, _t5796)
              v_cl_a = _t5797
              _t5798 = v_cloud_density
              _t5799 = min(1.0, _t5798)
              _t5800 = _t5799
              _t5801 = max(0.0, _t5800)
              v_cl_n = (0.5 * _pow(16.0, _t5801))
              _t5802 = 1.0 if _tr((1.0 if v_cloud_lfo_rate > 0.001 else 0.0)) else 0.0
              if _t5802:
                _t5802 = 1.0 if _tr((1.0 if v_cloud_lfo_depth > 0.001 else 0.0)) else 0.0
              if _tr(_t5802):
                v_cloud_lfo_phase = (v_cloud_lfo_phase + _div(v_cloud_lfo_rate, v_srate))
                if _tr((1.0 if v_cloud_lfo_phase >= 1.0 else 0.0)):
                  v_cloud_lfo_phase = (v_cloud_lfo_phase - 1.0)
                  _t5804 = v_cloud_lfo_phase
                else:
                  _t5804 = 0.0
                _t5803 = _t5804
              else:
                _t5803 = 0.0
              if _tr((1.0 if abs(v_cloud_lfo_shape - 0.0) < 0.00001 else 0.0)):
                _t5806 = ((2.0 * 3.141592653589793) * v_cloud_lfo_phase)
                _t5807 = math.sin(_t5806)
                _t5805 = _t5807
              else:
                if _tr((1.0 if abs(v_cloud_lfo_shape - 1.0) < 0.00001 else 0.0)):
                  _t5808 = ((v_cloud_lfo_phase * 2.0) - 1.0)
                else:
                  _t5808 = (1.0 - (v_cloud_lfo_phase * 2.0))
                _t5805 = _t5808
              v_lfo_val = _t5805
              if _tr((1.0 if abs(v_cloud_pos_mode - 0.0) < 0.00001 else 0.0)):
                _t5810 = 1.0 if _tr((1.0 if v_cloud_freeze >= 0.5 else 0.0)) else 0.0
                if _t5810:
                  _t5810 = 1.0 if _tr((1.0 if v_frz_prev >= 0.5 else 0.0)) else 0.0
                if _tr(_t5810):
                  _t5811 = v_frz_center
                else:
                  _t5811 = v_pos
                _t5809 = _t5811
              else:
                _t5809 = (v_eff_start + ((v_cloud_pos_pct * 0.01) * v_eff_len))
              v_cl_base = _t5809
              v_cl_center = (v_cl_base + (((v_lfo_val * (v_cloud_lfo_depth * 0.01)) * v_eff_len) * 0.5))
              v_cloud_center_draw = v_cl_center
              v_cl_timer = (v_cl_timer - 1.0)
              if _tr((1.0 if v_cl_timer <= 0.0 else 0.0)):
                _t5813 = f_cl_spawn()
                _t5814 = _div(((v_srate * 0.001) * v_cloud_size), v_cl_n)
                _t5815 = max(1.0, _t5814)
                v_cl_mean = _t5815
                _t5825 = v_cl_mean
                _t5817 = (1.0 - v_cl_a)
                _t5816 = _rand(0.1)
                _t5824 = (_t5817 * (0.95 + _t5816))
                _t5823 = v_cl_a
                _t5818 = _rand(1.0)
                _t5819 = (1.0 - _t5818)
                _t5820 = max(1e-06, _t5819)
                _t5821 = _t5820
                _t5822 = _log(_t5821)
                _t5826 = (_t5825 * (_t5824 + (_t5823 * (-_t5822))))
                _t5827 = max(1.0, _t5826)
                v_cl_timer = (v_cl_timer + _t5827)
                if _tr((1.0 if v_cl_timer < 1.0 else 0.0)):
                  v_cl_timer = 1.0
                  _t5828 = v_cl_timer
                else:
                  _t5828 = 0.0
                _t5812 = _t5828
              else:
                _t5812 = 0.0
              v_cl_out_l = 0.0
              v_cl_out_r = 0.0
              v_cl_act = 0.0
              v_cl_wsum = 0.0
              v_cl_ws = v_eff_start
              _t5829 = (v_eff_end - v_eff_start)
              _t5830 = max(16.0, _t5829)
              v_cl_wl = _t5830
              v_gi = 0.0
              for _t5831 in range(max(0, int(v_cl_max))):
                v_g_base = (v_cl_mem + (v_gi * v_cl_stride))
                if _tr(_mget(v_g_base + 2.0)):
                  v_cl_ph = _mget(v_g_base + 1.0)
                  v_cl_x = _div(v_cl_ph, _mget(v_g_base + 3.0))
                  if _tr((1.0 if v_cl_x >= 1.0 else 0.0)):
                    _t5834 = _ix(v_g_base + 2.0)
                    _t5835 = 0.0
                    _mset(_t5834, _t5835)
                    _t5833 = _t5835
                  else:
                    v_cl_atk = _mget(v_g_base + 8.0)
                    if _tr((1.0 if v_cl_x < v_cl_atk else 0.0)):
                      _t5837 = _div((3.141592653589793 * v_cl_x), v_cl_atk)
                      _t5838 = math.cos(_t5837)
                      _t5836 = (0.5 - (0.5 * _t5838))
                    else:
                      _t5839 = _div((3.141592653589793 * (v_cl_x - v_cl_atk)), (1.0 - v_cl_atk))
                      _t5840 = math.cos(_t5839)
                      _t5836 = (0.5 + (0.5 * _t5840))
                    v_cl_w = _t5836
                    if _tr((1.0 if _mget(v_g_base + 9.0) > 1.001 else 0.0)):
                      v_cl_w = _pow(v_cl_w, _mget(v_g_base + 9.0))
                      _t5841 = v_cl_w
                    else:
                      _t5841 = 0.0
                    v_cl_p = (_mget(v_g_base + 0.0) + (_mget(v_g_base + 5.0) * v_cl_ph))
                    v_cl_p = (v_cl_p - v_cl_ws)
                    _t5842 = _div(v_cl_p, v_cl_wl)
                    _t5843 = _floor(_t5842)
                    v_cl_p = (v_cl_p - (_t5843 * v_cl_wl))
                    v_cl_p = (v_cl_p + v_cl_ws)
                    _t5844 = v_cl_p
                    _t5845 = _floor(_t5844)
                    v_cl_i1 = _t5845
                    v_cl_fr = (v_cl_p - v_cl_i1)
                    v_cl_i0 = (v_cl_i1 - 1.0)
                    if _tr((1.0 if v_cl_i0 < v_cl_ws else 0.0)):
                      v_cl_i0 = (v_cl_i0 + v_cl_wl)
                      _t5846 = v_cl_i0
                    else:
                      _t5846 = 0.0
                    v_cl_i2 = (v_cl_i1 + 1.0)
                    if _tr((1.0 if v_cl_i2 >= (v_cl_ws + v_cl_wl) else 0.0)):
                      v_cl_i2 = (v_cl_i2 - v_cl_wl)
                      _t5847 = v_cl_i2
                    else:
                      _t5847 = 0.0
                    v_cl_i3 = (v_cl_i2 + 1.0)
                    if _tr((1.0 if v_cl_i3 >= (v_cl_ws + v_cl_wl) else 0.0)):
                      v_cl_i3 = (v_cl_i3 - v_cl_wl)
                      _t5848 = v_cl_i3
                    else:
                      _t5848 = 0.0
                    _t5849 = v_cl_i0
                    _t5850 = _floor(_t5849)
                    v_cl_i0 = _t5850
                    _t5851 = v_cl_i2
                    _t5852 = _floor(_t5851)
                    v_cl_i2 = _t5852
                    _t5853 = v_cl_i3
                    _t5854 = _floor(_t5853)
                    v_cl_i3 = _t5854
                    _t5857 = 1.0 if _tr(_mget(v_g_base + 15.0)) else 0.0
                    if _t5857:
                      _t5857 = 1.0 if _tr(v_frz_ready) else 0.0
                    _t5856 = 1.0 if _tr(_t5857) else 0.0
                    if _t5856:
                      _t5856 = 1.0 if _tr((1.0 if v_cl_i3 < v_frz_len else 0.0)) else 0.0
                    _t5855 = 1.0 if _tr(_t5856) else 0.0
                    if _t5855:
                      _t5855 = 1.0 if _tr((1.0 if v_cl_i0 < v_frz_len else 0.0)) else 0.0
                    if _tr(_t5855):
                      v_cl_bl = v_frz_l
                      v_cl_br = v_frz_r
                      _t5858 = v_cl_br
                    else:
                      v_cl_bl = v_left_buf
                      v_cl_br = v_right_buf
                      _t5858 = v_cl_br
                    _t5859 = v_cl_fr
                    _t5860 = _mget(v_cl_bl + v_cl_i0)
                    _t5861 = _mget(v_cl_bl + v_cl_i1)
                    _t5862 = _mget(v_cl_bl + v_cl_i2)
                    _t5863 = _mget(v_cl_bl + v_cl_i3)
                    _t5864 = f_hermite(_t5859, _t5860, _t5861, _t5862, _t5863)
                    v_cl_l = _t5864
                    _t5865 = v_cl_fr
                    _t5866 = _mget(v_cl_br + v_cl_i0)
                    _t5867 = _mget(v_cl_br + v_cl_i1)
                    _t5868 = _mget(v_cl_br + v_cl_i2)
                    _t5869 = _mget(v_cl_br + v_cl_i3)
                    _t5870 = f_hermite(_t5865, _t5866, _t5867, _t5868, _t5869)
                    v_cl_r = _t5870
                    if _tr((1.0 if _mget(v_g_base + 10.0) < 1.0 else 0.0)):
                      v_cl_c = _mget(v_g_base + 10.0)
                      _t5872 = _ix(v_g_base + 11.0)
                      _t5873 = (_mget(_t5872) + (v_cl_c * (v_cl_l - _mget(v_g_base + 11.0))))
                      _mset(_t5872, _t5873)
                      _t5874 = _ix(v_g_base + 12.0)
                      _t5875 = (_mget(_t5874) + (v_cl_c * (_mget(v_g_base + 11.0) - _mget(v_g_base + 12.0))))
                      _mset(_t5874, _t5875)
                      v_cl_l = _mget(v_g_base + 12.0)
                      _t5876 = _ix(v_g_base + 13.0)
                      _t5877 = (_mget(_t5876) + (v_cl_c * (v_cl_r - _mget(v_g_base + 13.0))))
                      _mset(_t5876, _t5877)
                      _t5878 = _ix(v_g_base + 14.0)
                      _t5879 = (_mget(_t5878) + (v_cl_c * (_mget(v_g_base + 13.0) - _mget(v_g_base + 14.0))))
                      _mset(_t5878, _t5879)
                      v_cl_r = _mget(v_g_base + 14.0)
                      _t5871 = v_cl_r
                    else:
                      _t5871 = 0.0
                    _t5880 = _mget(v_g_base + 4.0)
                    _t5881 = abs(_t5880)
                    if _tr((1.0 if _t5881 > 0.0001 else 0.0)):
                      v_cl_m = ((v_cl_l + v_cl_r) * 0.5)
                      v_cl_l = (v_cl_m * _mget(v_g_base + 6.0))
                      v_cl_r = (v_cl_m * _mget(v_g_base + 7.0))
                      _t5882 = v_cl_r
                    else:
                      _t5882 = 0.0
                    v_cl_out_l = (v_cl_out_l + (v_cl_l * v_cl_w))
                    v_cl_out_r = (v_cl_out_r + (v_cl_r * v_cl_w))
                    v_cl_act = (v_cl_act + 1.0)
                    v_cl_wsum = (v_cl_wsum + v_cl_w)
                    _t5883 = _ix(v_g_base + 1.0)
                    _t5884 = (v_cl_ph + 1.0)
                    _mset(_t5883, _t5884)
                    _t5833 = _t5884
                  _t5832 = _t5833
                else:
                  _t5832 = 0.0
                v_gi = (v_gi + 1.0)
              _t5885 = (v_cl_wl * 0.5)
              _t5886 = ((v_srate * 0.005) + (((v_cloud_spread + (v_cl_a * v_cl_a)) * v_cl_wl) * 0.5))
              _t5887 = min(_t5885, _t5886)
              v_cl_spr = _t5887
              _t5888 = _div((_div(v_cl_spr, v_srate) - 0.005), 0.05)
              _t5890 = (v_cl_a * 2.0)
              if _tr((1.0 if v_cloud_pitch_spread > 0.01 else 0.0)):
                _t5889 = 0.5
              else:
                _t5889 = 0.0
              _t5891 = (_t5890 + _t5889)
              _t5892 = max(_t5888, _t5891)
              _t5893 = _t5892
              _t5894 = min(1.0, _t5893)
              _t5895 = _t5894
              _t5896 = max(0.0, _t5895)
              v_cl_dec = _t5896
              _t5897 = v_cl_wsum
              _t5898 = max(1.0, _t5897)
              v_cl_g = _div(0.9, _pow(_t5898, (0.75 - (0.25 * v_cl_dec))))
              v_cl_out_l = (v_cl_out_l * v_cl_g)
              v_cl_out_r = (v_cl_out_r * v_cl_g)
              _t5899 = 1.0 if _tr((1.0 if v_cloud_diffuse > 0.001 else 0.0)) else 0.0
              if not _t5899:
                _t5899 = 1.0 if _tr(v_df_on) else 0.0
              if _tr(_t5899):
                v_df_on = (1.0 if v_cloud_diffuse > 0.001 else 0.0)
                v_df_fb = (0.35 + (0.5 * v_cloud_diffuse))
                v_df_xl = (v_cl_out_l + (v_df_fr * v_df_fb))
                v_df_xr = (v_cl_out_r + (v_df_fl * v_df_fb))
                _t5901 = v_df_a4
                _t5902 = v_df_a3
                _t5903 = v_df_a2
                _t5904 = v_df_a1
                _t5905 = v_df_xl
                _t5906 = f_df_ap(_t5904, _t5905, 0.62)
                _t5907 = _t5906
                _t5908 = f_df_ap(_t5903, _t5907, 0.62)
                _t5909 = _t5908
                _t5910 = f_df_ap(_t5902, _t5909, 0.62)
                _t5911 = _t5910
                _t5912 = f_df_ap(_t5901, _t5911, 0.62)
                v_df_xl = _t5912
                _t5913 = v_df_b4
                _t5914 = v_df_b3
                _t5915 = v_df_b2
                _t5916 = v_df_b1
                _t5917 = v_df_xr
                _t5918 = f_df_ap(_t5916, _t5917, 0.62)
                _t5919 = _t5918
                _t5920 = f_df_ap(_t5915, _t5919, 0.62)
                _t5921 = _t5920
                _t5922 = f_df_ap(_t5914, _t5921, 0.62)
                _t5923 = _t5922
                _t5924 = f_df_ap(_t5913, _t5923, 0.62)
                v_df_xr = _t5924
                _t5925 = v_df_dl
                _t5926 = f_df_rd(_t5925)
                v_df_fl = _t5926
                _t5927 = v_df_dr
                _t5928 = f_df_rd(_t5927)
                v_df_fr = _t5928
                v_df_lp_l = (v_df_lp_l + (0.35 * (v_df_xl - v_df_lp_l)))
                v_df_lp_r = (v_df_lp_r + (0.35 * (v_df_xr - v_df_lp_r)))
                _t5929 = v_df_dl
                _t5930 = v_df_lp_l
                _t5931 = f_df_wr(_t5929, _t5930)
                _t5932 = v_df_dr
                _t5933 = v_df_lp_r
                _t5934 = f_df_wr(_t5932, _t5933)
                _t5935 = ((v_cloud_diffuse * 3.141592653589793) * 0.5)
                _t5936 = math.sin(_t5935)
                v_df_w = _t5936
                _t5937 = ((v_cloud_diffuse * 3.141592653589793) * 0.5)
                _t5938 = math.cos(_t5937)
                v_df_d = _t5938
                v_df_k = (1.0 - (0.45 * v_cloud_diffuse))
                v_cl_out_l = ((v_cl_out_l * v_df_d) + ((v_df_xl * v_df_w) * v_df_k))
                v_cl_out_r = ((v_cl_out_r * v_df_d) + ((v_df_xr * v_df_w) * v_df_k))
                _t5900 = v_cl_out_r
              else:
                _t5900 = 0.0
              _t5939 = v_cl_out_l
              _t5940 = abs(_t5939)
              _t5941 = _t5940
              _t5942 = v_cl_out_r
              _t5943 = abs(_t5942)
              _t5944 = _t5943
              _t5945 = max(_t5941, _t5944)
              v_cl_lpk = _t5945
              if _tr((1.0 if v_cl_lpk > v_cl_lth else 0.0)):
                _t5946 = _div(v_cl_lth, v_cl_lpk)
              else:
                _t5946 = 1.0
              v_cl_lt = _t5946
              if _tr((1.0 if v_cl_lt <= v_cl_lh else 0.0)):
                v_cl_lh = v_cl_lt
                v_cl_lc = v_cl_ld
                _t5947 = v_cl_lc
              else:
                if _tr((1.0 if v_cl_lc > 0.0 else 0.0)):
                  v_cl_lc = (v_cl_lc - 1.0)
                  _t5948 = v_cl_lc
                else:
                  v_cl_lh = (v_cl_lh + ((1.0 - v_cl_lh) * v_cl_lrel))
                  _t5948 = v_cl_lh
                _t5947 = _t5948
              _t5950 = (v_cl_lh - v_cl_lg)
              if _tr((1.0 if v_cl_lh < v_cl_lg else 0.0)):
                _t5949 = v_cl_latt
              else:
                _t5949 = v_cl_lrel
              v_cl_lg = (v_cl_lg + (_t5950 * _t5949))
              v_cl_dl = _mget(v_cl_lk + v_cl_li)
              v_cl_dr = _mget(v_cl_lk + (256.0 + v_cl_li))
              _t5951 = _ix(v_cl_lk + v_cl_li)
              _t5952 = v_cl_out_l
              _mset(_t5951, _t5952)
              _t5953 = _ix(v_cl_lk + (256.0 + v_cl_li))
              _t5954 = v_cl_out_r
              _mset(_t5953, _t5954)
              v_cl_li = (v_cl_li + 1.0)
              if _tr((1.0 if v_cl_li >= v_cl_ld else 0.0)):
                v_cl_li = 0.0
                _t5955 = v_cl_li
              else:
                _t5955 = 0.0
              v_cl_out_l = (v_cl_dl * v_cl_lg)
              v_cl_out_r = (v_cl_dr * v_cl_lg)
              v_cmx = (v_cloud_mix * v_cloud_x)
              v_s0 = ((v_s0 * (1.0 - v_cmx)) + (v_cl_out_l * v_cmx))
              v_s1 = ((v_s1 * (1.0 - v_cmx)) + (v_cl_out_r * v_cmx))
              _t5787 = v_s1
            else:
              if _tr((1.0 if v_cloud_x <= 0.0001 else 0.0)):
                v_cl_timer = 0.0
                v_gi = 0.0
                for _t5957 in range(max(0, int(v_cl_max))):
                  v_g_base = (v_cl_mem + (v_gi * v_cl_stride))
                  _t5958 = _ix(v_g_base + 2.0)
                  _t5959 = 0.0
                  _mset(_t5958, _t5959)
                  v_gi = (v_gi + 1.0)
                _t5960 = v_cl_lk
                _t5961 = _memset(_t5960, 0.0, 512.0)
                v_cl_lg = 1.0
                v_cl_lh = 1.0
                v_cl_lc = 0.0
                _t5956 = v_cl_lc
              else:
                _t5956 = 0.0
              _t5787 = _t5956
            _t5962 = 1.0 if _tr(v_dub_gran) else 0.0
            if _t5962:
              _t5963 = 1.0 if _tr((0.0 if _tr(v_is_one_shot_mode) else 1.0)) else 0.0
              if not _t5963:
                _t5963 = 1.0 if _tr(v_one_shot_playing) else 0.0
              _t5962 = 1.0 if _tr(_t5963) else 0.0
            if _tr(_t5962):
              _t5965 = v_pos
              _t5966 = v_effective_rev
              _t5967 = 1.0 if _tr((0.0 if abs(v_state - 5.0) < 0.00001 else 1.0)) else 0.0
              if not _t5967:
                _t5967 = 1.0 if _tr(v_auto_rep_active) else 0.0
              _t5968 = _t5967
              _t5969 = f_dub_grain_tick(_t5965, _t5966, _t5968)
              _t5964 = _t5969
            else:
              _t5964 = 0.0
            _t5970 = 1.0 if _tr((0.0 if _tr(v_is_one_shot_mode) else 1.0)) else 0.0
            if not _t5970:
              _t5970 = 1.0 if _tr(v_one_shot_playing) else 0.0
            if _tr(_t5970):
              v_old_pos = v_pos
              _t5973 = v_pos_step
              if _tr(v_effective_rev):
                _t5972 = (-1.0)
              else:
                _t5972 = 1.0
              v_pos_step_actual = (_t5973 * _t5972)
              v_pos = (v_pos + v_pos_step_actual)
              v_wrapped = 0.0
              v_rd_last_st = v_pos_step_actual
              _t5979 = v_delay_len
              _t5978 = (2.0 * v_sl_pre_t)
              _t5974 = v_pos_step
              _t5975 = abs(_t5974)
              _t5976 = _t5975
              _t5977 = max(1.0, _t5976)
              v_wr_guard = ((_t5979 + (_t5978 * _t5977)) + 8.0)
              if _tr(v_is_one_shot_mode):
                if _tr(v_pingpong_on):
                  _t5982 = 1.0 if _tr((1.0 if v_pos >= v_eff_end else 0.0)) else 0.0
                  if not _t5982:
                    _t5982 = 1.0 if _tr((1.0 if v_pos < v_eff_start else 0.0)) else 0.0
                  if _tr(_t5982):
                    if _tr(v_one_shot_pp_state):
                      _t5985 = v_eff_start
                      _t5986 = v_eff_end
                      _t5987 = v_pos
                      _t5988 = min(_t5986, _t5987)
                      _t5989 = _t5988
                      _t5990 = max(_t5985, _t5989)
                      v_pos = _t5990
                      v_one_shot_playing = 0.0
                      _t5984 = v_one_shot_playing
                    else:
                      if _tr((1.0 if v_pos >= v_eff_end else 0.0)):
                        _t5991 = ((2.0 * v_eff_end) - v_pos)
                      else:
                        _t5991 = ((2.0 * v_eff_start) - v_pos)
                      v_pos = _t5991
                      v_ping_pong_dir = (-v_ping_pong_dir)
                      v_one_shot_pp_state = 1.0
                      v_wrapped = 1.0
                      if _tr(v_pending_part_switch):
                        _t5993 = v_target_part
                        _t5994 = f_switch_part(_t5993)
                        v_pending_part_switch = 0.0
                        _t5992 = v_pending_part_switch
                      else:
                        _t5992 = 0.0
                      _t5984 = _t5992
                    _t5983 = _t5984
                  else:
                    _t5983 = 0.0
                  _t5981 = _t5983
                else:
                  if _tr((1.0 if v_pos >= v_eff_end else 0.0)):
                    v_pos = v_eff_end
                    v_one_shot_playing = 0.0
                    _t5995 = v_one_shot_playing
                  else:
                    _t5995 = 0.0
                  if _tr((1.0 if v_pos < v_eff_start else 0.0)):
                    v_pos = v_eff_start
                    v_one_shot_playing = 0.0
                    _t5996 = v_one_shot_playing
                  else:
                    _t5996 = 0.0
                  _t5981 = _t5996
                _t5980 = _t5981
              else:
                _t5999 = v_delay_len
                _t5997 = v_pos_step
                _t5998 = abs(_t5997)
                _t6000 = ((_t5999 + (4.0 * _t5998)) + 16.0)
                _t6001 = (v_length * 0.25)
                _t6002 = min(_t6000, _t6001)
                v_ml_guard = _t6002
                if _tr(v_effective_rev):
                  _t6003 = (1.0 if v_pos <= v_ml_guard else 0.0)
                else:
                  _t6003 = (1.0 if v_pos >= (v_length - v_ml_guard) else 0.0)
                v_ml_trig = _t6003
                if _tr((0.0 if _tr(v_ml_trig) else 1.0)):
                  v_ml_cool = 0.0
                  _t6004 = v_ml_cool
                else:
                  _t6004 = 0.0
                _t6006 = 1.0 if _tr(v_ml_ok) else 0.0
                if _t6006:
                  _t6006 = 1.0 if _tr(v_ml_trig) else 0.0
                _t6005 = 1.0 if _tr(_t6006) else 0.0
                if _t6005:
                  _t6005 = 1.0 if _tr((0.0 if _tr(v_ml_cool) else 1.0)) else 0.0
                if _tr(_t6005):
                  _t6008 = f_multiply_extend()
                  v_ml_cool = 1.0
                  _t6007 = v_ml_cool
                else:
                  _t6007 = 0.0
                if _tr(v_pingpong_on):
                  if _tr((1.0 if v_pos < v_eff_start else 0.0)):
                    v_pos = ((2.0 * v_eff_start) - v_pos)
                    v_ping_pong_dir = (-v_ping_pong_dir)
                    v_wrapped = 1.0
                    if _tr(v_pending_part_switch):
                      _t6012 = v_target_part
                      _t6013 = f_switch_part(_t6012)
                      v_pending_part_switch = 0.0
                      _t6011 = v_pending_part_switch
                    else:
                      _t6011 = 0.0
                    _t6010 = _t6011
                  else:
                    if _tr((1.0 if v_pos >= v_eff_end else 0.0)):
                      v_pos = ((2.0 * v_eff_end) - v_pos)
                      v_ping_pong_dir = (-v_ping_pong_dir)
                      v_wrapped = 1.0
                      if _tr(v_pending_part_switch):
                        _t6016 = v_target_part
                        _t6017 = f_switch_part(_t6016)
                        v_pending_part_switch = 0.0
                        _t6015 = v_pending_part_switch
                      else:
                        _t6015 = 0.0
                      _t6014 = _t6015
                    else:
                      _t6014 = 0.0
                    _t6010 = _t6014
                  _t6009 = _t6010
                else:
                  _t6018 = 1.0 if _tr((1.0 if v_pos < v_eff_start else 0.0)) else 0.0
                  if _t6018:
                    _t6019 = 1.0 if _tr(v_effective_rev) else 0.0
                    if not _t6019:
                      _t6019 = 1.0 if _tr((1.0 if v_pos < (v_eff_start - v_wr_guard) else 0.0)) else 0.0
                    _t6018 = 1.0 if _tr(_t6019) else 0.0
                  if _tr(_t6018):
                    v_pos = (v_pos + v_eff_len)
                    v_wrapped = 1.0
                    if _tr(v_pending_part_switch):
                      _t6022 = v_target_part
                      _t6023 = f_switch_part(_t6022)
                      v_pending_part_switch = 0.0
                      _t6021 = v_pending_part_switch
                    else:
                      _t6021 = 0.0
                    _t6020 = _t6021
                  else:
                    _t6020 = 0.0
                  _t6024 = 1.0 if _tr((1.0 if v_pos >= v_eff_end else 0.0)) else 0.0
                  if _t6024:
                    _t6025 = 1.0 if _tr((0.0 if _tr(v_effective_rev) else 1.0)) else 0.0
                    if not _t6025:
                      _t6025 = 1.0 if _tr((1.0 if v_pos >= (v_eff_end + v_wr_guard) else 0.0)) else 0.0
                    _t6024 = 1.0 if _tr(_t6025) else 0.0
                  if _tr(_t6024):
                    v_pos = (v_pos - v_eff_len)
                    v_wrapped = 1.0
                    if _tr(v_pending_part_switch):
                      _t6028 = v_target_part
                      _t6029 = f_switch_part(_t6028)
                      v_pending_part_switch = 0.0
                      _t6027 = v_pending_part_switch
                    else:
                      _t6027 = 0.0
                    _t6026 = _t6027
                  else:
                    _t6026 = 0.0
                  _t6009 = _t6026
                _t5980 = _t6009
              if _tr(v_wrapped):
                v_dens_force = 1.0
                _t6030 = v_dens_force
              else:
                _t6030 = 0.0
              _t6032 = 1.0 if _tr(v_wrapped) else 0.0
              if _t6032:
                _t6032 = 1.0 if _tr((1.0 if v_state >= 3.0 else 0.0)) else 0.0
              _t6031 = 1.0 if _tr(_t6032) else 0.0
              if _t6031:
                _t6031 = 1.0 if _tr((1.0 if v_state <= 6.0 else 0.0)) else 0.0
              if _tr(_t6031):
                v_an_wrap_pending = 1.0
                _t6033 = v_an_wrap_pending
              else:
                _t6033 = 0.0
              _t6035 = 1.0 if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)) else 0.0
              if _t6035:
                _t6035 = 1.0 if _tr((1.0 if v_trans_count > 0.0 else 0.0)) else 0.0
              _t6034 = 1.0 if _tr(_t6035) else 0.0
              if _t6034:
                _t6034 = 1.0 if _tr((1.0 if v_sl_hi > v_sl_lo else 0.0)) else 0.0
              if _tr(_t6034):
                _t6039 = v_pos
                _t6038 = v_delay_len
                if _tr(v_effective_rev):
                  _t6037 = (-1.0)
                else:
                  _t6037 = 1.0
                v_sl_rd = (_t6039 + (_t6038 * _t6037))
                if _tr(v_effective_rev):
                  _t6040 = (v_sl_rd - v_sl_lo)
                else:
                  _t6040 = (v_sl_hi - v_sl_rd)
                v_slice_end_dist = _t6040
                if _tr((1.0 if v_slice_end_dist < (v_srate * 0.005) else 0.0)):
                  _t6042 = v_sl_run
                  _t6043 = _div(v_slice_end_dist, (v_srate * 0.005))
                  _t6044 = min(_t6042, _t6043)
                  _t6045 = _t6044
                  _t6046 = max(0.0, _t6045)
                  v_sl_run = _t6046
                  _t6041 = v_sl_run
                else:
                  if _tr(v_effective_rev):
                    _t6047 = (1.0 if v_sl_rd <= v_sl_lo else 0.0)
                  else:
                    _t6047 = (1.0 if v_sl_rd >= v_sl_hi else 0.0)
                  if _tr(_t6047):
                    v_sl_run = 0.0
                    _t6048 = v_sl_run
                  else:
                    _t6048 = 0.0
                  _t6041 = _t6048
                _t6036 = _t6041
              else:
                _t6036 = 0.0
              _t6050 = 1.0 if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)) else 0.0
              if _t6050:
                _t6050 = 1.0 if _tr((0.0 if _tr(v_dub_gran) else 1.0)) else 0.0
              _t6049 = 1.0 if _tr(_t6050) else 0.0
              if _t6049:
                _t6052 = 1.0 if _tr((1.0 if abs(v_state - 3.0) < 0.00001 else 0.0)) else 0.0
                if not _t6052:
                  _t6052 = 1.0 if _tr((1.0 if abs(v_state - 4.0) < 0.00001 else 0.0)) else 0.0
                _t6051 = 1.0 if _tr(_t6052) else 0.0
                if not _t6051:
                  _t6051 = 1.0 if _tr((1.0 if abs(v_state - 5.0) < 0.00001 else 0.0)) else 0.0
                _t6049 = 1.0 if _tr(_t6051) else 0.0
              v_sl_rec = _t6049
              if _tr((0.0 if _tr(v_sl_rec) else 1.0)):
                v_slw_last = (-1.0)
                v_sw_on = 0.0
                _t6053 = v_sw_on
              else:
                _t6053 = 0.0
              _t6056 = 1.0 if _tr((1.0 if v_lat_samps > 0.0 else 0.0)) else 0.0
              if _t6056:
                _t6056 = 1.0 if _tr((0.0 if _tr(v_pingpong_on) else 1.0)) else 0.0
              _t6055 = 1.0 if _tr(_t6056) else 0.0
              if _t6055:
                _t6055 = 1.0 if _tr((0.0 if _tr(v_dub_gran) else 1.0)) else 0.0
              _t6054 = 1.0 if _tr(_t6055) else 0.0
              if _t6054:
                _t6059 = 1.0 if _tr((1.0 if v_state >= 3.0 else 0.0)) else 0.0
                if _t6059:
                  _t6059 = 1.0 if _tr((1.0 if v_state <= 6.0 else 0.0)) else 0.0
                _t6058 = 1.0 if _tr(_t6059) else 0.0
                if not _t6058:
                  _t6058 = 1.0 if _tr(v_rp_tail_on) else 0.0
                _t6057 = 1.0 if _tr(_t6058) else 0.0
                if not _t6057:
                  _t6057 = 1.0 if _tr((1.0 if v_dub_pf > 0.0 else 0.0)) else 0.0
                _t6054 = 1.0 if _tr(_t6057) else 0.0
              if _tr(_t6054):
                _t6063 = v_lat_samps
                _t6061 = v_pos_step
                _t6062 = abs(_t6061)
                _t6064 = (_t6063 * _t6062)
                _t6065 = (v_eff_len * 0.25)
                _t6066 = min(_t6064, _t6065)
                _t6068 = _t6066
                if _tr(v_effective_rev):
                  _t6067 = 1.0
                else:
                  _t6067 = (-1.0)
                _t6060 = (_t6068 * _t6067)
              else:
                _t6060 = 0.0
              v_wr_off = _t6060
              if _tr((1.0 if abs(v_state - 3.0) < 0.00001 else 0.0)):
                if _tr(v_dub_gran):
                  if _tr(v_wrapped):
                    _t6073 = v_rev_on
                    _t6072 = 1.0 if _tr(v_pingpong_on) else 0.0
                    if _t6072:
                      _t6072 = 1.0 if _tr((1.0 if v_ping_pong_dir < 0.0 else 0.0)) else 0.0
                    _t6074 = (0.0 if _tr((0.0 if abs(_t6073 - _t6072) < 0.00001 else 1.0)) else 1.0)
                    _t6075 = f_dub_commit_begin(_t6074)
                    _t6076 = _rand(2.0)
                    v_dub_pan = (_t6076 - 1.0)
                    _t6071 = v_dub_pan
                  else:
                    if _tr((0.0 if _tr(v_effective_rev) else 1.0)):
                      _t6078 = v_pos
                      _t6079 = f_dub_merge_behind(_t6078)
                      _t6077 = _t6079
                    else:
                      _t6077 = 0.0
                    _t6071 = _t6077
                  _t6070 = _t6071
                else:
                  v_sw_on = 0.0
                  _t6080 = (v_dub_pf + v_dub_pfk)
                  _t6081 = min(1.0, _t6080)
                  v_dub_pf = _t6081
                  v_dub_g = v_dub_pf
                  if _tr(v_sl_rec):
                    _t6083 = f_slw_move(1.0)
                    _t6082 = _t6083
                  else:
                    _t6084 = v_old_pos
                    _t6085 = v_pos
                    _t6086 = v_wrapped
                    _t6087 = v_effective_rev
                    _t6088 = f_write_move(_t6084, _t6085, _t6086, _t6087, 1.0)
                    _t6082 = _t6088
                  v_dub_g = 1.0
                  if _tr(v_wrapped):
                    _t6090 = _rand(2.0)
                    v_dub_pan = (_t6090 - 1.0)
                    _t6089 = v_dub_pan
                  else:
                    _t6089 = 0.0
                  _t6070 = _t6089
                _t6093 = 1.0 if _tr(v_rp_tail_on) else 0.0
                if _t6093:
                  _t6093 = 1.0 if _tr((1.0 if v_replace_fade > 0.0 else 0.0)) else 0.0
                _t6092 = 1.0 if _tr(_t6093) else 0.0
                if _t6092:
                  _t6092 = 1.0 if _tr((0.0 if _tr(v_dub_gran) else 1.0)) else 0.0
                _t6091 = 1.0 if _tr(_t6092) else 0.0
                if _t6091:
                  _t6091 = 1.0 if _tr((0.0 if _tr(v_sl_rec) else 1.0)) else 0.0
                if _tr(_t6091):
                  _t6095 = v_old_pos
                  _t6096 = v_pos
                  _t6097 = v_wrapped
                  _t6098 = v_effective_rev
                  _t6099 = f_write_move(_t6095, _t6096, _t6097, _t6098, 2.0)
                  _t6094 = _t6099
                else:
                  v_rp_tail_on = 0.0
                  _t6094 = v_rp_tail_on
                _t6100 = (v_replace_fade - v_replace_fade_coeff)
                _t6101 = max(0.0, _t6100)
                v_replace_fade = _t6101
                v_wet_s0 = v_s0
                v_wet_s1 = v_s1
                _t6069 = v_wet_s1
              else:
                if _tr((1.0 if abs(v_state - 4.0) < 0.00001 else 0.0)):
                  v_dub_pf = 0.0
                  if _tr(v_dub_gran):
                    if _tr(v_wrapped):
                      _t6106 = v_rev_on
                      _t6105 = 1.0 if _tr(v_pingpong_on) else 0.0
                      if _t6105:
                        _t6105 = 1.0 if _tr((1.0 if v_ping_pong_dir < 0.0 else 0.0)) else 0.0
                      _t6107 = (0.0 if _tr((0.0 if abs(_t6106 - _t6105) < 0.00001 else 1.0)) else 1.0)
                      _t6108 = f_dub_commit_begin(_t6107)
                      _t6109 = _rand(2.0)
                      v_dub_pan = (_t6109 - 1.0)
                      _t6104 = v_dub_pan
                    else:
                      _t6104 = 0.0
                    _t6103 = _t6104
                  else:
                    if _tr(v_sl_rec):
                      _t6111 = f_slc_move(2.0)
                      _t6110 = _t6111
                    else:
                      _t6112 = v_old_pos
                      _t6113 = v_pos
                      _t6114 = v_wrapped
                      _t6115 = v_effective_rev
                      _t6116 = f_write_move(_t6112, _t6113, _t6114, _t6115, 2.0)
                      _t6110 = _t6116
                    if _tr(v_wrapped):
                      _t6118 = _rand(2.0)
                      v_dub_pan = (_t6118 - 1.0)
                      _t6117 = v_dub_pan
                    else:
                      _t6117 = 0.0
                    _t6103 = _t6117
                  _t6119 = (v_replace_fade + v_replace_fade_coeff)
                  _t6120 = min(1.0, _t6119)
                  v_replace_fade = _t6120
                  v_rp_tail_on = 1.0
                  v_wet_s0 = v_s0
                  v_wet_s1 = v_s1
                  _t6102 = v_wet_s1
                else:
                  if _tr((1.0 if abs(v_state - 5.0) < 0.00001 else 0.0)):
                    v_dub_pf = 0.0
                    if _tr((1.0 if v_curr_peak > v_ar_in else 0.0)):
                      _t6122 = v_ar_att
                    else:
                      _t6122 = v_ar_rel
                    v_ar_in = (v_ar_in + (_t6122 * (v_curr_peak - v_ar_in)))
                    _t6123 = 1.0 if _tr(v_sl_rec) else 0.0
                    if _t6123:
                      _t6123 = 1.0 if _tr(v_sw_on) else 0.0
                    if _tr(_t6123):
                      _t6124 = v_sw_pos
                    else:
                      _t6124 = v_pos
                    v_ar_k = (_t6124 + v_wr_off)
                    if _tr((1.0 if v_ar_k < v_eff_start else 0.0)):
                      v_ar_k = (v_ar_k + v_eff_len)
                      _t6125 = v_ar_k
                    else:
                      if _tr((1.0 if v_ar_k >= v_eff_end else 0.0)):
                        v_ar_k = (v_ar_k - v_eff_len)
                        _t6126 = v_ar_k
                      else:
                        _t6126 = 0.0
                      _t6125 = _t6126
                    _t6127 = (v_length - 1.0)
                    _t6128 = v_ar_k
                    _t6129 = min(_t6127, _t6128)
                    _t6130 = _t6129
                    _t6131 = max(0.0, _t6130)
                    _t6132 = _t6131
                    _t6133 = _floor(_t6132)
                    v_ar_k = _t6133
                    _t6134 = _mget(v_left_buf + v_ar_k)
                    _t6135 = abs(_t6134)
                    _t6136 = _t6135
                    _t6137 = _mget(v_right_buf + v_ar_k)
                    _t6138 = abs(_t6137)
                    _t6139 = _t6138
                    _t6140 = max(_t6136, _t6139)
                    v_ar_x = _t6140
                    if _tr((1.0 if v_ar_x > v_ar_lp else 0.0)):
                      _t6141 = v_ar_att
                    else:
                      _t6141 = v_ar_rel
                    v_ar_lp = (v_ar_lp + (_t6141 * (v_ar_x - v_ar_lp)))
                    if _tr(v_auto_rep_active):
                      _t6143 = 1.0 if _tr((1.0 if v_ar_in < (v_trans_sens * 0.7) else 0.0)) else 0.0
                      if not _t6143:
                        _t6143 = 1.0 if _tr((1.0 if v_ar_in < (v_ar_lp * 0.7) else 0.0)) else 0.0
                      if _tr(_t6143):
                        v_ar_cnt = (v_ar_cnt + 1.0)
                        if _tr((1.0 if v_ar_cnt >= v_ar_hold else 0.0)):
                          v_auto_rep_active = 0.0
                          v_ar_cnt = 0.0
                          _t6145 = v_ar_cnt
                        else:
                          _t6145 = 0.0
                        _t6144 = _t6145
                      else:
                        v_ar_cnt = 0.0
                        _t6144 = v_ar_cnt
                      _t6142 = _t6144
                    else:
                      _t6146 = 1.0 if _tr((1.0 if v_ar_in >= v_trans_sens else 0.0)) else 0.0
                      if _t6146:
                        _t6146 = 1.0 if _tr((1.0 if v_ar_in >= v_ar_lp else 0.0)) else 0.0
                      if _tr(_t6146):
                        v_auto_rep_active = 1.0
                        v_ar_cnt = 0.0
                        _t6148 = _rand(2.0)
                        v_dub_pan = (_t6148 - 1.0)
                        _t6147 = v_dub_pan
                      else:
                        _t6147 = 0.0
                      _t6142 = _t6147
                    _t6149 = 1.0 if _tr(v_dub_gran) else 0.0
                    if _t6149:
                      _t6149 = 1.0 if _tr(v_wrapped) else 0.0
                    if _tr(_t6149):
                      _t6152 = v_rev_on
                      _t6151 = 1.0 if _tr(v_pingpong_on) else 0.0
                      if _t6151:
                        _t6151 = 1.0 if _tr((1.0 if v_ping_pong_dir < 0.0 else 0.0)) else 0.0
                      _t6153 = (0.0 if _tr((0.0 if abs(_t6152 - _t6151) < 0.00001 else 1.0)) else 1.0)
                      _t6154 = f_dub_commit_begin(_t6153)
                      _t6150 = _t6154
                    else:
                      _t6150 = 0.0
                    if _tr(v_auto_rep_active):
                      _t6156 = (v_replace_fade + v_ar_up)
                      _t6157 = min(1.0, _t6156)
                      _t6155 = _t6157
                    else:
                      _t6158 = (v_replace_fade - v_ar_dn)
                      _t6159 = max(0.0, _t6158)
                      _t6155 = _t6159
                    v_replace_fade = _t6155
                    _t6160 = 1.0 if _tr((0.0 if _tr(v_dub_gran) else 1.0)) else 0.0
                    if _t6160:
                      _t6160 = 1.0 if _tr((1.0 if v_replace_fade > 0.0 else 0.0)) else 0.0
                    if _tr(_t6160):
                      if _tr(v_sl_rec):
                        _t6163 = f_slc_move(2.0)
                        _t6162 = _t6163
                      else:
                        _t6164 = v_old_pos
                        _t6165 = v_pos
                        _t6166 = v_wrapped
                        _t6167 = v_effective_rev
                        _t6168 = f_write_move(_t6164, _t6165, _t6166, _t6167, 2.0)
                        _t6162 = _t6168
                      _t6161 = _t6162
                    else:
                      v_sw_on = 0.0
                      _t6161 = v_sw_on
                    v_rp_tail_on = (0.0 if _tr(v_sl_rec) else 1.0)
                    v_wet_s0 = v_s0
                    v_wet_s1 = v_s1
                    _t6121 = v_wet_s1
                  else:
                    if _tr((1.0 if abs(v_state - 6.0) < 0.00001 else 0.0)):
                      v_dub_pf = 0.0
                      _t6170 = v_old_pos
                      _t6171 = v_pos
                      _t6172 = v_wrapped
                      _t6173 = v_effective_rev
                      _t6174 = f_write_move(_t6170, _t6171, _t6172, _t6173, 1.0)
                      if _tr(v_wrapped):
                        _t6176 = _rand(2.0)
                        v_dub_pan = (_t6176 - 1.0)
                        _t6175 = v_dub_pan
                      else:
                        _t6175 = 0.0
                      _t6178 = 1.0 if _tr(v_rp_tail_on) else 0.0
                      if _t6178:
                        _t6178 = 1.0 if _tr((1.0 if v_replace_fade > 0.0 else 0.0)) else 0.0
                      _t6177 = 1.0 if _tr(_t6178) else 0.0
                      if _t6177:
                        _t6177 = 1.0 if _tr((0.0 if _tr(v_dub_gran) else 1.0)) else 0.0
                      if _tr(_t6177):
                        _t6180 = v_old_pos
                        _t6181 = v_pos
                        _t6182 = v_wrapped
                        _t6183 = v_effective_rev
                        _t6184 = f_write_move(_t6180, _t6181, _t6182, _t6183, 2.0)
                        _t6179 = _t6184
                      else:
                        v_rp_tail_on = 0.0
                        _t6179 = v_rp_tail_on
                      _t6185 = (v_replace_fade - v_replace_fade_coeff)
                      _t6186 = max(0.0, _t6185)
                      v_replace_fade = _t6186
                      v_wet_s0 = v_s0
                      v_wet_s1 = v_s1
                      _t6169 = v_wet_s1
                    else:
                      _t6188 = 1.0 if _tr(v_rp_tail_on) else 0.0
                      if _t6188:
                        _t6188 = 1.0 if _tr((1.0 if v_replace_fade > 0.0 else 0.0)) else 0.0
                      _t6187 = 1.0 if _tr(_t6188) else 0.0
                      if _t6187:
                        _t6187 = 1.0 if _tr((0.0 if _tr(v_dub_gran) else 1.0)) else 0.0
                      if _tr(_t6187):
                        _t6190 = v_old_pos
                        _t6191 = v_pos
                        _t6192 = v_wrapped
                        _t6193 = v_effective_rev
                        _t6194 = f_write_move(_t6190, _t6191, _t6192, _t6193, 2.0)
                        _t6189 = _t6194
                      else:
                        v_rp_tail_on = 0.0
                        _t6189 = v_rp_tail_on
                      _t6196 = 1.0 if _tr((1.0 if v_dub_pf > 0.0 else 0.0)) else 0.0
                      if _t6196:
                        _t6196 = 1.0 if _tr((0.0 if _tr(v_dub_gran) else 1.0)) else 0.0
                      _t6195 = 1.0 if _tr(_t6196) else 0.0
                      if _t6195:
                        _t6195 = 1.0 if _tr((1.0 if abs(v_state - 2.0) < 0.00001 else 0.0)) else 0.0
                      if _tr(_t6195):
                        _t6198 = (v_dub_pf - v_dub_pfk)
                        _t6199 = max(0.0, _t6198)
                        v_dub_pf = _t6199
                        v_dub_g = v_dub_pf
                        _t6200 = v_old_pos
                        _t6201 = v_pos
                        _t6202 = v_wrapped
                        _t6203 = v_effective_rev
                        _t6204 = f_write_move(_t6200, _t6201, _t6202, _t6203, 1.0)
                        v_dub_g = 1.0
                        _t6197 = v_dub_g
                      else:
                        v_dub_pf = 0.0
                        _t6197 = v_dub_pf
                      _t6205 = (v_replace_fade - v_replace_fade_coeff)
                      _t6206 = max(0.0, _t6205)
                      v_replace_fade = _t6206
                      v_wet_s0 = v_s0
                      v_wet_s1 = v_s1
                      _t6169 = v_wet_s1
                    _t6121 = _t6169
                  _t6102 = _t6121
                _t6069 = _t6102
              _t5971 = _t6069
            else:
              v_wet_s0 = 0.0
              v_wet_s1 = 0.0
              if _tr(v_acc_cur_dirty):
                _t6208 = f_dub_commit_begin(1.0)
                _t6207 = _t6208
              else:
                _t6207 = 0.0
              v_rd_valid = 0.0
              _t5971 = v_rd_valid
            _t5332 = _t5971
          else:
            _t5332 = 0.0
          _t5308 = _t5332
        _t5294 = _t5308
      _t5270 = _t5294
    _t5267 = _t5270
  _t6209 = 1.0 if _tr((1.0 if v_state >= 2.0 else 0.0)) else 0.0
  if _t6209:
    _t6209 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
  if _tr((0.0 if _tr(_t6209) else 1.0)):
    v_rd_valid = 0.0
    v_xf_on = 0.0
    v_pd_prev_l = 0.0
    v_pd_prev_r = 0.0
    _t6210 = v_pd_prev_r
  else:
    _t6210 = 0.0
  if _tr(v_cm_active):
    _t6212 = v_sm_speed
    _t6213 = abs(_t6212)
    _t6214 = (_t6213 * 4.0)
    _t6215 = _floor(_t6214)
    _t6216 = (16.0 + _t6215)
    _t6217 = f_dub_commit_step(_t6216)
    _t6211 = _t6217
  else:
    _t6211 = 0.0
  v_prev_in0 = v_in0
  v_prev_in1 = v_in1
  _t6218 = f_sampler_mode_now()
  v_smp_mode = _t6218
  v_smp_armed = (1.0 if v_smp_mode > 0.0 else 0.0)
  v_smp_kmode = (1.0 if abs(v_smp_mode - 2.0) < 0.00001 else 0.0)
  _t6219 = 1.0 if _tr((0.0 if abs(v_smp_mode - v_smp_prev_mode) < 0.00001 else 1.0)) else 0.0
  if not _t6219:
    _t6219 = 1.0 if _tr(v_smp_alloff) else 0.0
  if _tr(_t6219):
    _t6221 = v_smp_quick_rel
    _t6222 = f_sampler_release_all(_t6221)
    v_smp_alloff = 0.0
    _t6220 = v_smp_alloff
  else:
    _t6220 = 0.0
  v_smp_prev_mode = v_smp_mode
  _t6223 = 0
  while True:
    if not _tr((1.0 if v_smp_ev_i < v_smp_ev_n else 0.0)): break
    if _tr((1.0 if _mget(v_smp_ev_vel + v_smp_ev_i) > 0.0 else 0.0)):
      if _tr(v_smp_armed):
        _t6226 = _mget(v_smp_ev_note + v_smp_ev_i)
        _t6227 = _mget(v_smp_ev_vel + v_smp_ev_i)
        _t6228 = f_sampler_note_on(_t6226, _t6227)
        _t6225 = _t6228
      else:
        _t6225 = 0.0
      _t6224 = _t6225
    else:
      _t6229 = _mget(v_smp_ev_note + v_smp_ev_i)
      _t6230 = f_sampler_note_off(_t6229)
      _t6224 = _t6230
    v_smp_ev_i = (v_smp_ev_i + 1.0)
    _t6223 += 1
    if _t6223 > 1000000: break
  _t6231 = f_sampler_render()
  v_wet_s0 = (v_wet_s0 + v_smp_l)
  v_wet_s1 = (v_wet_s1 + v_smp_r)
  v_br_mix_s = (v_br_mix_s + ((v_br_mix - v_br_mix_s) * 0.0015))
  _t6233 = 1.0 if _tr(v_br_on) else 0.0
  if _t6233:
    _t6233 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
  _t6232 = 1.0 if _tr(_t6233) else 0.0
  if _t6232:
    _t6232 = 1.0 if _tr((1.0 if v_br_bg_e > (v_br_bg_s + 16.0) else 0.0)) else 0.0
  if _tr(_t6232):
    v_bg_len = (v_br_bg_e - v_br_bg_s)
    _t6235 = f_bg_sync_ok()
    v_br_bg_clk = _t6235
    if _tr(v_br_bg_clk):
      _t6237 = v_br_bg_s
      _t6238 = v_bg_len
      _t6239 = f_sync_expected_win(_t6237, _t6238)
      v_br_bg_pos = _t6239
      _t6236 = v_br_bg_pos
    else:
      _t6236 = 0.0
    _t6241 = 1.0 if _tr((1.0 if v_br_mix_s < 0.999 else 0.0)) else 0.0
    if _t6241:
      _t6241 = 1.0 if _tr((1.0 if v_state >= 2.0 else 0.0)) else 0.0
    _t6240 = 1.0 if _tr(_t6241) else 0.0
    if _t6240:
      _t6240 = 1.0 if _tr((1.0 if v_state <= 6.0 else 0.0)) else 0.0
    if _tr(_t6240):
      _t6243 = v_br_bg_pos
      _t6244 = _floor(_t6243)
      v_bg_p1 = _t6244
      v_bg_fr = (v_br_bg_pos - v_bg_p1)
      if _tr((1.0 if v_bg_p1 < v_br_bg_s else 0.0)):
        v_bg_p1 = v_br_bg_s
        _t6245 = v_bg_p1
      else:
        _t6245 = 0.0
      if _tr((1.0 if v_bg_p1 >= v_br_bg_e else 0.0)):
        v_bg_p1 = (v_br_bg_e - 1.0)
        _t6246 = v_bg_p1
      else:
        _t6246 = 0.0
      v_bg_p0 = (v_bg_p1 - 1.0)
      if _tr((1.0 if v_bg_p0 < v_br_bg_s else 0.0)):
        v_bg_p0 = (v_bg_p0 + v_bg_len)
        _t6247 = v_bg_p0
      else:
        _t6247 = 0.0
      v_bg_p2 = (v_bg_p1 + 1.0)
      if _tr((1.0 if v_bg_p2 >= v_br_bg_e else 0.0)):
        v_bg_p2 = (v_bg_p2 - v_bg_len)
        _t6248 = v_bg_p2
      else:
        _t6248 = 0.0
      v_bg_p3 = (v_bg_p2 + 1.0)
      if _tr((1.0 if v_bg_p3 >= v_br_bg_e else 0.0)):
        v_bg_p3 = (v_bg_p3 - v_bg_len)
        _t6249 = v_bg_p3
      else:
        _t6249 = 0.0
      _t6250 = v_bg_fr
      _t6251 = _mget(v_left_buf + v_bg_p0)
      _t6252 = _mget(v_left_buf + v_bg_p1)
      _t6253 = _mget(v_left_buf + v_bg_p2)
      _t6254 = _mget(v_left_buf + v_bg_p3)
      _t6255 = f_hermite(_t6250, _t6251, _t6252, _t6253, _t6254)
      v_bg_l = _t6255
      _t6256 = v_bg_fr
      _t6257 = _mget(v_right_buf + v_bg_p0)
      _t6258 = _mget(v_right_buf + v_bg_p1)
      _t6259 = _mget(v_right_buf + v_bg_p2)
      _t6260 = _mget(v_right_buf + v_bg_p3)
      _t6261 = f_hermite(_t6256, _t6257, _t6258, _t6259, _t6260)
      v_bg_r = _t6261
      _t6262 = ((v_fade_ms * 0.001) * v_srate)
      _t6263 = (v_bg_len * 0.5)
      _t6264 = min(_t6262, _t6263)
      v_bg_fs = _t6264
      v_bg_env = 1.0
      _t6265 = 1.0 if _tr((1.0 if v_bg_fs > 0.0 else 0.0)) else 0.0
      if _t6265:
        _t6265 = 1.0 if _tr((1.0 if (v_br_bg_pos - v_br_bg_s) < v_bg_fs else 0.0)) else 0.0
      if _tr(_t6265):
        v_bg_env = _div((v_br_bg_pos - v_br_bg_s), v_bg_fs)
        _t6266 = v_bg_env
      else:
        _t6266 = 0.0
      _t6267 = 1.0 if _tr((1.0 if v_bg_fs > 0.0 else 0.0)) else 0.0
      if _t6267:
        _t6267 = 1.0 if _tr((1.0 if (v_br_bg_e - v_br_bg_pos) < v_bg_fs else 0.0)) else 0.0
      if _tr(_t6267):
        _t6269 = v_bg_env
        _t6270 = _div((v_br_bg_e - v_br_bg_pos), v_bg_fs)
        _t6271 = min(_t6269, _t6270)
        v_bg_env = _t6271
        _t6268 = v_bg_env
      else:
        _t6268 = 0.0
      _t6272 = ((v_br_mix_s * 3.141592653589793) * 0.5)
      _t6273 = math.sin(_t6272)
      v_bg_wg = _t6273
      _t6274 = ((v_br_mix_s * 3.141592653589793) * 0.5)
      _t6275 = math.cos(_t6274)
      v_bg_dg = _t6275
      v_wet_s0 = ((v_wet_s0 * v_bg_wg) + ((v_bg_l * v_bg_env) * v_bg_dg))
      v_wet_s1 = ((v_wet_s1 * v_bg_wg) + ((v_bg_r * v_bg_env) * v_bg_dg))
      _t6242 = v_wet_s1
    else:
      _t6242 = 0.0
    if _tr((0.0 if _tr(v_br_bg_clk) else 1.0)):
      _t6278 = v_pos_step
      if _tr(v_effective_rev):
        _t6277 = (-1.0)
      else:
        _t6277 = 1.0
      v_br_bg_pos = (v_br_bg_pos + (_t6278 * _t6277))
      _t6276 = v_br_bg_pos
    else:
      _t6276 = 0.0
    v_bg_rp = (v_br_bg_pos - v_br_bg_s)
    _t6281 = v_bg_len
    _t6279 = _div(v_bg_rp, v_bg_len)
    _t6280 = _floor(_t6279)
    v_bg_rp = (v_bg_rp - (_t6281 * _t6280))
    v_br_bg_pos = (v_br_bg_s + v_bg_rp)
    _t6234 = v_br_bg_pos
  else:
    _t6234 = 0.0
  v_slx_mix_s = (v_slx_mix_s + ((v_slx_mix - v_slx_mix_s) * 0.0015))
  _t6283 = 1.0 if _tr((1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)) else 0.0
  if _t6283:
    _t6283 = 1.0 if _tr((1.0 if v_length > 0.0 else 0.0)) else 0.0
  _t6282 = 1.0 if _tr(_t6283) else 0.0
  if _t6282:
    _t6282 = 1.0 if _tr((1.0 if v_eff_len > 16.0 else 0.0)) else 0.0
  if _tr(_t6282):
    if _tr((0.0 if abs(v_slx_prev - 1.0) < 0.00001 else 1.0)):
      _t6286 = v_eff_start
      _t6287 = (v_eff_end - 1.0)
      _t6288 = v_pos
      _t6289 = min(_t6287, _t6288)
      _t6290 = _t6289
      _t6291 = max(_t6286, _t6290)
      v_slx_pos = _t6291
      _t6285 = v_slx_pos
    else:
      _t6285 = 0.0
    _t6292 = f_bg_sync_ok()
    v_slx_clk = _t6292
    if _tr(v_slx_clk):
      _t6294 = v_loop_start
      _t6295 = v_loop_width
      _t6296 = f_sync_expected_win(_t6294, _t6295)
      v_slx_pos = _t6296
      _t6293 = v_slx_pos
    else:
      _t6293 = 0.0
    _t6298 = 1.0 if _tr((1.0 if v_slx_mix_s < 0.999 else 0.0)) else 0.0
    if _t6298:
      _t6298 = 1.0 if _tr((1.0 if v_state >= 2.0 else 0.0)) else 0.0
    _t6297 = 1.0 if _tr(_t6298) else 0.0
    if _t6297:
      _t6297 = 1.0 if _tr((1.0 if v_state <= 6.0 else 0.0)) else 0.0
    if _tr(_t6297):
      _t6300 = v_slx_pos
      _t6301 = _floor(_t6300)
      v_slx_p1 = _t6301
      v_slx_fr = (v_slx_pos - v_slx_p1)
      if _tr((1.0 if v_slx_p1 < v_eff_start else 0.0)):
        _t6303 = v_eff_start
        _t6304 = _floor(_t6303)
        v_slx_p1 = _t6304
        _t6302 = v_slx_p1
      else:
        _t6302 = 0.0
      if _tr((1.0 if v_slx_p1 >= v_eff_end else 0.0)):
        _t6306 = v_eff_end
        _t6307 = _floor(_t6306)
        v_slx_p1 = (_t6307 - 1.0)
        _t6305 = v_slx_p1
      else:
        _t6305 = 0.0
      v_slx_p0 = (v_slx_p1 - 1.0)
      if _tr((1.0 if v_slx_p0 < v_eff_start else 0.0)):
        v_slx_p0 = (v_slx_p0 + v_eff_len)
        _t6308 = v_slx_p0
      else:
        _t6308 = 0.0
      v_slx_p2 = (v_slx_p1 + 1.0)
      if _tr((1.0 if v_slx_p2 >= v_eff_end else 0.0)):
        v_slx_p2 = (v_slx_p2 - v_eff_len)
        _t6309 = v_slx_p2
      else:
        _t6309 = 0.0
      v_slx_p3 = (v_slx_p2 + 1.0)
      if _tr((1.0 if v_slx_p3 >= v_eff_end else 0.0)):
        v_slx_p3 = (v_slx_p3 - v_eff_len)
        _t6310 = v_slx_p3
      else:
        _t6310 = 0.0
      _t6311 = v_slx_p0
      _t6312 = _floor(_t6311)
      v_slx_p0 = _t6312
      _t6313 = v_slx_p2
      _t6314 = _floor(_t6313)
      v_slx_p2 = _t6314
      _t6315 = v_slx_p3
      _t6316 = _floor(_t6315)
      v_slx_p3 = _t6316
      _t6317 = v_slx_fr
      _t6318 = _mget(v_left_buf + v_slx_p0)
      _t6319 = _mget(v_left_buf + v_slx_p1)
      _t6320 = _mget(v_left_buf + v_slx_p2)
      _t6321 = _mget(v_left_buf + v_slx_p3)
      _t6322 = f_hermite(_t6317, _t6318, _t6319, _t6320, _t6321)
      v_slx_l = _t6322
      _t6323 = v_slx_fr
      _t6324 = _mget(v_right_buf + v_slx_p0)
      _t6325 = _mget(v_right_buf + v_slx_p1)
      _t6326 = _mget(v_right_buf + v_slx_p2)
      _t6327 = _mget(v_right_buf + v_slx_p3)
      _t6328 = f_hermite(_t6323, _t6324, _t6325, _t6326, _t6327)
      v_slx_r = _t6328
      _t6329 = ((v_fade_ms * 0.001) * v_srate)
      _t6330 = (v_eff_len * 0.5)
      _t6331 = min(_t6329, _t6330)
      v_slx_fs = _t6331
      v_slx_env = 1.0
      _t6332 = 1.0 if _tr((1.0 if v_slx_fs > 0.0 else 0.0)) else 0.0
      if _t6332:
        _t6332 = 1.0 if _tr((1.0 if (v_slx_pos - v_eff_start) < v_slx_fs else 0.0)) else 0.0
      if _tr(_t6332):
        v_slx_env = _div((v_slx_pos - v_eff_start), v_slx_fs)
        _t6333 = v_slx_env
      else:
        _t6333 = 0.0
      _t6334 = 1.0 if _tr((1.0 if v_slx_fs > 0.0 else 0.0)) else 0.0
      if _t6334:
        _t6334 = 1.0 if _tr((1.0 if (v_eff_end - v_slx_pos) < v_slx_fs else 0.0)) else 0.0
      if _tr(_t6334):
        _t6336 = v_slx_env
        _t6337 = _div((v_eff_end - v_slx_pos), v_slx_fs)
        _t6338 = min(_t6336, _t6337)
        v_slx_env = _t6338
        _t6335 = v_slx_env
      else:
        _t6335 = 0.0
      _t6339 = ((v_slx_mix_s * 3.141592653589793) * 0.5)
      _t6340 = math.sin(_t6339)
      v_slx_wg = _t6340
      _t6341 = ((v_slx_mix_s * 3.141592653589793) * 0.5)
      _t6342 = math.cos(_t6341)
      v_slx_dg = _t6342
      v_wet_s0 = ((v_wet_s0 * v_slx_wg) + ((v_slx_l * v_slx_env) * v_slx_dg))
      v_wet_s1 = ((v_wet_s1 * v_slx_wg) + ((v_slx_r * v_slx_env) * v_slx_dg))
      _t6299 = v_wet_s1
    else:
      _t6299 = 0.0
    if _tr((0.0 if _tr(v_slx_clk) else 1.0)):
      if _tr(v_link_eff):
        _t6344 = v_varispeed
      else:
        _t6344 = v_sm_speed
      _t6346 = _t6344
      if _tr(v_effective_rev):
        _t6345 = (-1.0)
      else:
        _t6345 = 1.0
      v_slx_pos = (v_slx_pos + (_t6346 * _t6345))
      _t6343 = v_slx_pos
    else:
      _t6343 = 0.0
    v_slx_rp = (v_slx_pos - v_eff_start)
    _t6349 = v_eff_len
    _t6347 = _div(v_slx_rp, v_eff_len)
    _t6348 = _floor(_t6347)
    v_slx_rp = (v_slx_rp - (_t6349 * _t6348))
    v_slx_pos = (v_eff_start + v_slx_rp)
    _t6284 = v_slx_pos
  else:
    _t6284 = 0.0
  v_slx_prev = (1.0 if abs(v_play_mode - 1.0) < 0.00001 else 0.0)
  _t6350 = ((v_mix * 3.141592653589793) * 0.5)
  _t6351 = math.cos(_t6350)
  v_dry_gain = _t6351
  _t6352 = ((v_mix * 3.141592653589793) * 0.5)
  _t6353 = math.sin(_t6352)
  v_wet_gain = _t6353
  if _tr((1.0 if v_state_transition_fade < 0.999 else 0.0)):
    v_wet_s0 = (v_wet_s0 * v_state_transition_fade)
    v_wet_s1 = (v_wet_s1 * v_state_transition_fade)
    _t6357 = v_state_transition_fade
    _t6355 = (v_srate * 0.008)
    _t6356 = max(1.0, _t6355)
    _t6358 = (_t6357 + _div(1.0, _t6356))
    _t6359 = min(1.0, _t6358)
    v_state_transition_fade = _t6359
    _t6354 = v_state_transition_fade
  else:
    _t6354 = 0.0
  if _tr(v_lp_mute):
    _t6360 = 0.0
  else:
    _t6360 = 1.0
  v_mute_g = (v_mute_g + ((_t6360 - v_mute_g) * 0.004))
  v_out0 = ((v_in0 * v_dry_gain) + ((v_wet_s0 * v_wet_gain) * v_mute_g))
  v_out1 = ((v_in1 * v_dry_gain) + ((v_wet_s1 * v_wet_gain) * v_mute_g))
  v_out0 = (v_out0 * v_out_vol)
  v_out1 = (v_out1 * v_out_vol)
  _t6361 = v_out0
  _t6362 = f_transparent_soft_clip(_t6361)
  v_out0 = _t6362
  _t6363 = v_out1
  _t6364 = f_transparent_soft_clip(_t6363)
  v_out1 = _t6364
  _t6365 = (-1.0)
  _t6366 = v_out0
  _t6367 = min(1.0, _t6366)
  _t6368 = _t6367
  _t6369 = max(_t6365, _t6368)
  v_spl0 = _t6369
  _t6370 = (-1.0)
  _t6371 = v_out1
  _t6372 = min(1.0, _t6371)
  _t6373 = _t6372
  _t6374 = max(_t6370, _t6373)
  v_spl1 = _t6374
  _t6375 = (v_peak_out_vu * v_vu_rel)
  _t6376 = v_spl0
  _t6377 = abs(_t6376)
  _t6378 = _t6377
  _t6379 = v_spl1
  _t6380 = abs(_t6379)
  _t6381 = _t6380
  _t6382 = max(_t6378, _t6381)
  _t6383 = _t6382
  _t6384 = max(_t6375, _t6383)
  v_peak_out_vu = _t6384
  _t6385 = (v_peak_loop_vu * v_vu_rel)
  _t6386 = v_wet_s0
  _t6387 = abs(_t6386)
  _t6388 = _t6387
  _t6389 = v_wet_s1
  _t6390 = abs(_t6389)
  _t6391 = _t6390
  _t6392 = max(_t6388, _t6391)
  _t6393 = _t6392
  _t6394 = max(_t6385, _t6393)
  v_peak_loop_vu = _t6394
  if _tr((1.0 if v_length > 0.0 else 0.0)):
    _t6395 = (_div(v_master_pos, v_length) * 100.0)
  else:
    _t6395 = 0.0
  v_ghost_pos_pct = _t6395
  return 0
