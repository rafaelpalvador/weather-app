package app.ceu.tempo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.concurrent.thread
import kotlin.math.roundToInt

/* Widgets do ecrã inicial do Céu.
 * O app grava a localização em "ceu-widget.json"; o widget lê esse ficheiro,
 * vai buscar a previsão ao Open-Meteo e guarda a última resposta para mostrar sem rede. */
object CeuWidgetData {
    const val ACTION_REFRESH = "app.ceu.tempo.WIDGET_REFRESH"
    private const val PREFS = "ceu_widget"
    private const val FILE = "ceu-widget.json"

    private fun settingsFile(ctx: Context): File? {
        val cands = mutableListOf<File>()
        cands.add(File(ctx.dataDir, FILE))
        cands.add(File(ctx.filesDir, FILE))
        ctx.getExternalFilesDir(null)?.let { cands.add(File(it, FILE)) }
        cands.firstOrNull { it.exists() }?.let { return it }
        return try {
            ctx.dataDir.walkTopDown().maxDepth(3).firstOrNull { it.isFile && it.name == FILE }
        } catch (e: Exception) { null }
    }

    fun settings(ctx: Context): JSONObject? = try {
        settingsFile(ctx)?.readText()?.let { JSONObject(it) }
    } catch (e: Exception) { null }

    fun cached(ctx: Context): JSONObject? = try {
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString("fc", null)?.let { JSONObject(it) }
    } catch (e: Exception) { null }

    fun fetch(ctx: Context): Boolean {
        val s = settings(ctx) ?: return false
        val lat = s.optDouble("lat", Double.NaN)
        val lon = s.optDouble("lon", Double.NaN)
        if (lat.isNaN() || lon.isNaN()) return false
        val model = s.optString("source", "auto")
        val q = StringBuilder("https://api.open-meteo.com/v1/forecast?latitude=")
            .append(String.format(Locale.US, "%.4f", lat)).append("&longitude=").append(String.format(Locale.US, "%.4f", lon))
            .append("&timezone=auto&forecast_days=7")
            .append("&current=temperature_2m,apparent_temperature,is_day,weather_code")
            .append("&hourly=temperature_2m,weather_code,is_day,precipitation_probability")
            .append("&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max")
        if (model.isNotEmpty() && model != "auto") q.append("&models=").append(model)
        return try {
            val con = URL(q.toString()).openConnection() as HttpURLConnection
            con.connectTimeout = 8000
            con.readTimeout = 8000
            con.setRequestProperty("User-Agent", "Ceu-Tempo-Widget/0.1")
            val txt = con.inputStream.bufferedReader().use { it.readText() }
            con.disconnect()
            val j = JSONObject(txt)
            if (!j.has("hourly")) return false
            j.put("_name", s.optString("name", ""))
            j.put("_ts", System.currentTimeMillis())
            ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString("fc", j.toString()).apply()
            true
        } catch (e: Exception) { false }
    }

    /* ---------- textos e ícones ---------- */
    private fun kind(c: Int): String = when {
        c == 0 || c == 1 -> "clear"
        c == 2 -> "partly"
        c == 3 -> "cloudy"
        c == 45 || c == 48 -> "fog"
        c in 51..67 || c in 80..82 -> "rain"
        c in 71..77 || c == 85 || c == 86 -> "snow"
        c >= 95 -> "storm"
        else -> "cloudy"
    }

    fun cond(c: Int, day: Boolean): String = when (c) {
        0 -> if (day) "Céu limpo" else "Noite limpa"
        1 -> "Pouco nublado"
        2 -> "Parcialmente nublado"
        3 -> "Nublado"
        45, 48 -> "Nevoeiro"
        51, 53, 55, 56, 57 -> "Chuvisco"
        61 -> "Chuva fraca"
        63 -> "Chuva"
        65, 66, 67 -> "Chuva forte"
        71, 73, 75, 77 -> "Neve"
        80, 81 -> "Aguaceiros"
        82 -> "Aguaceiros fortes"
        85, 86 -> "Aguaceiros de neve"
        95 -> "Trovoada"
        96, 99 -> "Trovoada com granizo"
        else -> "—"
    }

    fun icon(c: Int, day: Boolean): Int = when (kind(c)) {
        "clear" -> if (day) R.drawable.wi_clear_day else R.drawable.wi_clear_night
        "partly" -> if (day) R.drawable.wi_partly_day else R.drawable.wi_partly_night
        "fog" -> R.drawable.wi_fog
        "rain" -> R.drawable.wi_rain
        "snow" -> R.drawable.wi_snow
        "storm" -> R.drawable.wi_storm
        else -> R.drawable.wi_cloudy
    }

    private fun bg(c: Int, day: Boolean): Int = when (kind(c)) {
        "clear", "partly" -> if (day) R.drawable.wbg_clear else R.drawable.wbg_night
        "rain" -> R.drawable.wbg_rain
        "storm" -> R.drawable.wbg_storm
        "snow" -> R.drawable.wbg_snow
        "fog" -> R.drawable.wbg_fog
        else -> if (day) R.drawable.wbg_cloudy else R.drawable.wbg_night_cloudy
    }

    private fun deg(v: Double): String = if (v.isNaN()) "–" else "${v.roundToInt()}°"
    private val WD = arrayOf("Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb")

    private fun nowIndex(times: JSONArray): Int {
        val key = SimpleDateFormat("yyyy-MM-dd'T'HH", Locale.US).format(Date())
        for (i in 0 until times.length()) if (times.optString(i).startsWith(key)) return i
        return 0
    }

    /* ---------- desenhar ---------- */
    fun render(ctx: Context, type: String): RemoteViews {
        val layout = if (type == "small") R.layout.ceu_widget_small else R.layout.ceu_widget_wide
        val v = RemoteViews(ctx.packageName, layout)
        val open = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)
        if (open != null) {
            v.setOnClickPendingIntent(R.id.w_root, PendingIntent.getActivity(ctx, 0, open, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT))
        }
        val cls = when (type) { "small" -> CeuWidgetSmall::class.java; "hours" -> CeuWidgetHours::class.java; else -> CeuWidgetDays::class.java }
        val rf = Intent(ctx, cls).setAction(ACTION_REFRESH)
        v.setOnClickPendingIntent(R.id.w_refresh, PendingIntent.getBroadcast(ctx, type.hashCode(), rf, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT))

        val j = cached(ctx)
        if (j == null) {
            v.setTextViewText(R.id.w_city, "Céu")
            v.setTextViewText(R.id.w_temp, "–")
            v.setTextViewText(R.id.w_cond, if (settings(ctx) == null) "Abre o app para definir a localização" else "A obter a previsão…")
            v.setTextViewText(R.id.w_hilo, "")
            return v
        }
        val h = j.getJSONObject("hourly")
        val d = j.getJSONObject("daily")
        val cur = j.optJSONObject("current")
        val ht = h.getJSONArray("time")
        val i0 = nowIndex(ht)
        val age = System.currentTimeMillis() - j.optLong("_ts", 0)
        val fresh = cur != null && age < 60 * 60 * 1000
        val temp = if (fresh) cur!!.optDouble("temperature_2m") else h.getJSONArray("temperature_2m").optDouble(i0)
        val code = if (fresh) cur!!.optInt("weather_code") else h.getJSONArray("weather_code").optInt(i0)
        val day = (if (fresh) cur!!.optInt("is_day", 1) else h.getJSONArray("is_day").optInt(i0, 1)) == 1
        val dt = d.getJSONArray("time")
        val todayKey = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        var d0 = 0
        for (k in 0 until dt.length()) if (dt.optString(k) == todayKey) { d0 = k; break }
        val tmax = d.getJSONArray("temperature_2m_max")
        val tmin = d.getJSONArray("temperature_2m_min")

        v.setInt(R.id.w_root, "setBackgroundResource", bg(code, day))
        v.setTextViewText(R.id.w_city, j.optString("_name", "").ifEmpty { "Céu" })
        v.setTextViewText(R.id.w_temp, deg(temp))
        v.setImageViewResource(R.id.w_icon, icon(code, day))
        v.setTextViewText(R.id.w_cond, cond(code, day))
        v.setTextViewText(R.id.w_hilo, "Máx. ${deg(tmax.optDouble(d0))}  Mín. ${deg(tmin.optDouble(d0))}")

        if (type != "small") {
            val cells = arrayOf(
                intArrayOf(R.id.c0t, R.id.c0i, R.id.c0v, R.id.c0p), intArrayOf(R.id.c1t, R.id.c1i, R.id.c1v, R.id.c1p),
                intArrayOf(R.id.c2t, R.id.c2i, R.id.c2v, R.id.c2p), intArrayOf(R.id.c3t, R.id.c3i, R.id.c3v, R.id.c3p),
                intArrayOf(R.id.c4t, R.id.c4i, R.id.c4v, R.id.c4p), intArrayOf(R.id.c5t, R.id.c5i, R.id.c5v, R.id.c5p)
            )
            if (type == "hours") {
                val hT = h.getJSONArray("temperature_2m"); val hC = h.getJSONArray("weather_code")
                val hD = h.getJSONArray("is_day"); val hP = h.getJSONArray("precipitation_probability")
                for (k in cells.indices) {
                    val i = i0 + 1 + k
                    if (i >= ht.length()) break
                    v.setTextViewText(cells[k][0], ht.optString(i).substring(11, 13) + "h")
                    v.setImageViewResource(cells[k][1], icon(hC.optInt(i), hD.optInt(i, 1) == 1))
                    v.setTextViewText(cells[k][2], deg(hT.optDouble(i)))
                    val p = hP.optInt(i, 0)
                    v.setTextViewText(cells[k][3], if (p >= 20) "$p%" else "")
                }
            } else {
                val dC = d.getJSONArray("weather_code"); val dP = d.getJSONArray("precipitation_probability_max")
                val cal = Calendar.getInstance()
                for (k in cells.indices) {
                    val i = d0 + k
                    if (i >= dt.length()) break
                    val parts = dt.optString(i).split("-")
                    var label = "Hoje"
                    if (k > 0 && parts.size == 3) {
                        cal.set(parts[0].toInt(), parts[1].toInt() - 1, parts[2].toInt())
                        label = WD[cal.get(Calendar.DAY_OF_WEEK) - 1]
                    }
                    v.setTextViewText(cells[k][0], label)
                    v.setImageViewResource(cells[k][1], icon(dC.optInt(i), true))
                    v.setTextViewText(cells[k][2], "${deg(tmax.optDouble(i))} ${deg(tmin.optDouble(i))}")
                    val p = dP.optInt(i, 0)
                    v.setTextViewText(cells[k][3], if (p >= 20) "$p%" else "")
                }
            }
        }
        return v
    }

    fun drawAll(ctx: Context) {
        val mgr = AppWidgetManager.getInstance(ctx)
        val all = listOf(
            Pair(CeuWidgetSmall::class.java, "small"),
            Pair(CeuWidgetHours::class.java, "hours"),
            Pair(CeuWidgetDays::class.java, "days")
        )
        for ((cls, type) in all) {
            val ids = mgr.getAppWidgetIds(ComponentName(ctx, cls))
            if (ids.isEmpty()) continue
            val views = render(ctx, type)
            for (id in ids) mgr.updateAppWidget(id, views)
        }
    }
}

abstract class CeuWidgetBase : AppWidgetProvider() {
    private fun refreshAsync(ctx: Context) {
        val app = ctx.applicationContext
        val pending = goAsync()
        thread {
            try {
                CeuWidgetData.fetch(app)
                CeuWidgetData.drawAll(app)
            } catch (e: Exception) {
            } finally {
                pending.finish()
            }
        }
    }

    override fun onUpdate(ctx: Context, mgr: AppWidgetManager, ids: IntArray) {
        CeuWidgetData.drawAll(ctx)
        refreshAsync(ctx)
    }

    override fun onReceive(ctx: Context, intent: Intent) {
        super.onReceive(ctx, intent)
        if (intent.action == CeuWidgetData.ACTION_REFRESH) refreshAsync(ctx)
    }
}

class CeuWidgetSmall : CeuWidgetBase()
class CeuWidgetHours : CeuWidgetBase()
class CeuWidgetDays : CeuWidgetBase()
