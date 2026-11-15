use serde::Serialize;

// ---------- pedidos HTTP feitos pelo Rust (sem limites de CORS do WebView) ----------
#[derive(Serialize)]
struct HttpOut {
    status: u16,
    body: String,
}

#[tauri::command]
async fn http_get(url: String) -> Result<HttpOut, String> {
    if !url.starts_with("https://") {
        return Err("Só são permitidos endereços https".into());
    }
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(15))
        .user_agent("Ceu-Tempo/0.1 (app pessoal de previsao do tempo)")
        .build()
        .map_err(|e| e.to_string())?;
    let rs = client
        .get(&url)
        .header("Accept", "application/json")
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let status = rs.status().as_u16();
    let body = rs.text().await.map_err(|e| e.to_string())?;
    Ok(HttpOut { status, body })
}

// ---------- widgets do ecrã inicial: o app grava aqui a localização ----------
#[tauri::command]
fn save_widget_data(app: tauri::AppHandle, json: String) -> Result<(), String> {
    use tauri::Manager;
    let dir = app.path().app_data_dir().map_err(|e| e.to_string())?;
    std::fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    std::fs::write(dir.join("ceu-widget.json"), json).map_err(|e| e.to_string())
}

// ---------- imagens da cena para os widgets (JPEG em base64 vindo do canvas) ----------
fn b64_decode(s: &str) -> Result<Vec<u8>, String> {
    let mut out = Vec::with_capacity(s.len() * 3 / 4);
    let (mut buf, mut bits) = (0u32, 0u32);
    for c in s.bytes() {
        let v = match c {
            b'A'..=b'Z' => c - b'A',
            b'a'..=b'z' => c - b'a' + 26,
            b'0'..=b'9' => c - b'0' + 52,
            b'+' => 62,
            b'/' => 63,
            b'=' | b'\n' | b'\r' | b' ' => continue,
            _ => return Err("base64 inválido".into()),
        } as u32;
        buf = (buf << 6) | v;
        bits += 6;
        if bits >= 8 {
            bits -= 8;
            out.push((buf >> bits) as u8);
            buf &= (1 << bits) - 1;
        }
    }
    Ok(out)
}

#[tauri::command]
fn save_widget_image(app: tauri::AppHandle, name: String, b64: String) -> Result<(), String> {
    use tauri::Manager;
    if name.is_empty() || name.len() > 64 || !name.chars().all(|c| c.is_ascii_alphanumeric() || c == '-' || c == '.') {
        return Err("nome inválido".into());
    }
    let data = b64_decode(b64.split(',').last().unwrap_or(""))?;
    let dir = app.path().app_data_dir().map_err(|e| e.to_string())?;
    std::fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    let tmp = dir.join(format!("{}.tmp", name));
    std::fs::write(&tmp, data).map_err(|e| e.to_string())?;
    std::fs::rename(&tmp, dir.join(&name)).map_err(|e| e.to_string())
}

// ---------- widget no ambiente de trabalho (só desktop) ----------
#[cfg(desktop)]
mod desk {
    use tauri::{AppHandle, Manager, PhysicalPosition, PhysicalSize, WebviewUrl, WebviewWindowBuilder};
    use tauri::window::{Effect, EffectsBuilder};

    fn geo_file(app: &AppHandle) -> Option<std::path::PathBuf> {
        app.path().app_data_dir().ok().map(|d| d.join("desktop-widget.json"))
    }
    pub fn save_geo(app: &AppHandle) {
        if let (Some(w), Some(f)) = (app.get_webview_window("widget"), geo_file(app)) {
            if let (Ok(p), Ok(s)) = (w.outer_position(), w.inner_size()) {
                let _ = std::fs::create_dir_all(f.parent().unwrap());
                let _ = std::fs::write(f, format!("{{\"x\":{},\"y\":{},\"w\":{},\"h\":{}}}", p.x, p.y, s.width, s.height));
            }
        }
    }
    pub fn show(app: &AppHandle) -> Result<(), String> {
        if let Some(w) = app.get_webview_window("widget") {
            let _ = w.show();
            return Ok(());
        }
        let w = WebviewWindowBuilder::new(app, "widget", WebviewUrl::App("index.html?widget=1".into()))
            .title("Céu · Widget")
            .inner_size(380.0, 210.0)
            .min_inner_size(240.0, 130.0)
            .decorations(false)
            .transparent(true)
            .shadow(true)
            .skip_taskbar(true)
            .always_on_bottom(true)
            .resizable(true)
            .visible(false)
            .build()
            .map_err(|e| e.to_string())?;
        if let Some(f) = geo_file(app) {
            if let Ok(t) = std::fs::read_to_string(f) {
                if let Ok(v) = serde_json::from_str::<serde_json::Value>(&t) {
                    let g = |k: &str| v.get(k).and_then(|x| x.as_i64());
                    if let (Some(x), Some(y)) = (g("x"), g("y")) { let _ = w.set_position(PhysicalPosition::new(x as i32, y as i32)); }
                    if let (Some(ww), Some(hh)) = (g("w"), g("h")) { let _ = w.set_size(PhysicalSize::new(ww as u32, hh as u32)); }
                }
            }
        }
        let h = app.clone();
        w.on_window_event(move |e| match e {
            tauri::WindowEvent::Moved(_) | tauri::WindowEvent::Resized(_) => save_geo(&h),
            _ => {}
        });
        let _ = w.show();
        Ok(())
    }
    pub fn glass(app: &AppHandle, on: bool) -> Result<(), String> {
        let w = app.get_webview_window("widget").ok_or("sem widget")?;
        if on {
            w.set_effects(EffectsBuilder::new().effect(Effect::Acrylic).build()).map_err(|e| e.to_string())
        } else {
            w.set_effects(None::<tauri::utils::config::WindowEffectsConfig>).map_err(|e| e.to_string())
        }
    }
    pub fn open_main(app: &AppHandle) {
        if let Some(m) = app.get_webview_window("main") {
            let _ = m.show();
            let _ = m.unminimize();
            let _ = m.set_focus();
        }
    }
}

#[tauri::command]
fn show_desktop_widget(app: tauri::AppHandle) -> Result<(), String> {
    #[cfg(desktop)]
    return desk::show(&app);
    #[cfg(not(desktop))]
    { let _ = app; Ok(()) }
}

#[tauri::command]
fn hide_desktop_widget(app: tauri::AppHandle) -> Result<(), String> {
    use tauri::Manager;
    if let Some(w) = app.get_webview_window("widget") { let _ = w.hide(); }
    Ok(())
}

#[tauri::command]
fn set_widget_glass(app: tauri::AppHandle, on: bool) -> Result<(), String> {
    #[cfg(desktop)]
    return desk::glass(&app, on);
    #[cfg(not(desktop))]
    { let _ = (app, on); Ok(()) }
}

#[tauri::command]
fn set_widget_size(app: tauri::AppHandle, w: f64, h: f64) -> Result<(), String> {
    use tauri::Manager;
    if let Some(win) = app.get_webview_window("widget") {
        win.set_size(tauri::LogicalSize::new(w, h)).map_err(|e| e.to_string())?;
    }
    Ok(())
}

#[tauri::command]
fn open_main_window(app: tauri::AppHandle) {
    #[cfg(desktop)]
    desk::open_main(&app);
    #[cfg(not(desktop))]
    let _ = app;
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .setup(|_app| {
            #[cfg(mobile)]
            _app.handle().plugin(tauri_plugin_geolocation::init())?;
            #[cfg(desktop)]
            {
                use tauri::Manager;
                use tauri::menu::{Menu, MenuItem};
                use tauri::tray::TrayIconBuilder;
                _app.handle().plugin(tauri_plugin_autostart::init(tauri_plugin_autostart::MacosLauncher::LaunchAgent, Some(vec!["--widget"])))?;
                // arranque com o Windows: só o widget, sem a janela principal
                if std::env::args().any(|a| a == "--widget") {
                    if let Some(m) = _app.get_webview_window("main") { let _ = m.hide(); }
                }
                let show_w = MenuItem::with_id(_app, "widget", "Mostrar widget", true, None::<&str>)?;
                let open_m = MenuItem::with_id(_app, "open", "Abrir o Céu", true, None::<&str>)?;
                let quit = MenuItem::with_id(_app, "quit", "Sair", true, None::<&str>)?;
                let menu = Menu::with_items(_app, &[&show_w, &open_m, &quit])?;
                let mut tray = TrayIconBuilder::new().menu(&menu).tooltip("Céu").on_menu_event(|app, ev| match ev.id.as_ref() {
                    "widget" => { let _ = desk::show(app); }
                    "open" => desk::open_main(app),
                    "quit" => app.exit(0),
                    _ => {}
                });
                if let Some(ic) = _app.default_window_icon() { tray = tray.icon(ic.clone()); }
                tray.build(_app)?;
            }
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![http_get, save_widget_data, save_widget_image, show_desktop_widget, hide_desktop_widget, set_widget_glass, set_widget_size, open_main_window])
        .run(tauri::generate_context!())
        .expect("erro ao iniciar o app");
}
