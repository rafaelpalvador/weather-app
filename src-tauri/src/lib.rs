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

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .setup(|_app| {
            #[cfg(mobile)]
            _app.handle().plugin(tauri_plugin_geolocation::init())?;
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![http_get, save_widget_data, save_widget_image])
        .run(tauri::generate_context!())
        .expect("erro ao iniciar o app");
}
