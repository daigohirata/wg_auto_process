from tinydb import TinyDB
import json
from datetime import datetime
import os
import matplotlib.pyplot as plt
from datetime import datetime

db = TinyDB("/hsm/nu/wagasci/data/run15/database/wagascidb.db")
data = db.all()
data = sorted(data, key=lambda r: r["run_number"], reverse=True)

def ts_to_str(ts):
    return datetime.fromtimestamp(ts).strftime("%Y-%m-%d %H:%M:%S")

def topology_to_detector_names(topology_raw):
    try:
        topology = json.loads(topology_raw)
    except:
        return []

    difs = set(topology.keys())
    detectors = []

    north = {"0","1"}
    south = {"2","3"}
    upstream = {"4","5"}
    downstream = {"6","7"}

    if north.issubset(difs):
        detectors.append("WallMRD North")
    else:
        if "0" in difs: detectors.append("WallMRD North Top")
        if "1" in difs: detectors.append("WallMRD North Bottom")

    if south.issubset(difs):
        detectors.append("WallMRD South")
    else:
        if "2" in difs: detectors.append("WallMRD South Top")
        if "3" in difs: detectors.append("WallMRD South Bottom")

    if upstream.issubset(difs):
        detectors.append("WAGASCI Upstream")
    else:
        if "4" in difs: detectors.append("WAGASCI Upstream Top")
        if "5" in difs: detectors.append("WAGASCI Upstream Side")

    if downstream.issubset(difs):
        detectors.append("WAGASCI Downstream")
    else:
        if "6" in difs: detectors.append("WAGASCI Downstream Top")
        if "7" in difs: detectors.append("WAGASCI Downstream Side")

    return detectors

def plot_run_timeline(data):
    """
    横軸：時間
    縦軸：Run number
    年ごと（2025, 2026）に別グラフで表示
    """

    # Run番号昇順
    data_sorted = sorted(data, key=lambda r: r["run_number"])

    # 年ごとに分類
    runs_2025 = []
    runs_2026 = []

    for run in data_sorted:
        start_dt = datetime.fromtimestamp(run["start_time"])
        year = start_dt.year

        if year == 2025:
            runs_2025.append(run)
        elif year == 2026:
            runs_2026.append(run)

    # ===== 2025 =====
    if runs_2025:
        plt.figure()
        for run in runs_2025:
            run_number = run["run_number"]
            start = datetime.fromtimestamp(run["start_time"])
            stop = datetime.fromtimestamp(run["stop_time"])

            plt.hlines(y=run_number, xmin=start, xmax=stop)

        plt.xlabel("Time")
        plt.ylabel("Run Number")
        plt.title("Run Duration Timeline (2025)")
        plt.xticks(rotation=45)
        plt.tight_layout()
        plt.savefig("/hsm/nu/wagasci/wg_auto_process/monitor/timeline_2025.png")
        plt.close()

    # ===== 2026 =====
    if runs_2026:
        plt.figure()
        for run in runs_2026:
            run_number = run["run_number"]
            start = datetime.fromtimestamp(run["start_time"])
            stop = datetime.fromtimestamp(run["stop_time"])

            plt.hlines(y=run_number, xmin=start, xmax=stop)

        plt.xlabel("Time")
        plt.ylabel("Run Number")
        plt.title("Run Duration Timeline (2026)")
        plt.xticks(rotation=45)
        plt.tight_layout()
        plt.savefig("/hsm/nu/wagasci/wg_auto_process/monitor/timeline_2026.png")
        plt.close()

html = """
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>WAGASCI Rawdata Database</title>
<style>
body {
    font-family: "Segoe UI", sans-serif;
    margin: 40px;
    background:#f4f6f9;
}

table {
    border-collapse: collapse;
    width: 100%;
    background:white;
    box-shadow:0 2px 8px rgba(0,0,0,0.1);
    margin-bottom:40px;
}

th, td {
    padding: 10px;
}

th {
    background: linear-gradient(90deg,#34495e,#2c3e50);
    color:white;
    text-align:left;
}

td:nth-child(2),
td:nth-child(3) {
    text-align:right;
}

tr:hover {
    background:#eef;
}

.run-card {
    background:white;
    padding:20px;
    margin-bottom:25px;
    border-radius:10px;
    box-shadow:0 4px 10px rgba(0,0,0,0.08);
}

.badge {
    padding:4px 8px;
    border-radius:12px;
    font-size:0.8em;
    font-weight:bold;
    margin-right:5px;
    display:inline-block;
}

.good { background:#27ae60; color:white; }
.bad { background:#c0392b; color:white; }

.detector {
    background:#3498db;
    color:white;
}

.path {
    font-family: "Consolas", monospace;
    font-size:0.85em;
    background:#eef;
    padding:3px 6px;
    border-radius:4px;
}

.file {
    font-family: "Consolas", monospace;
    background:#dde6ff;
    padding:3px 6px;
    border-radius:4px;
}

details {
    margin-top:10px;
}
</style>
</head>
"""

last_update = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
html += f"""
<body>
<h1>WAGASCI Run Database (Last update: {last_update})</h1>
<div class="timeline-container">
    <img src="timeline_2025.png">
    <img src="timeline_2026.png">
</div>
"""

# ===== サマリーテーブル =====
html += "<table>"
html += "<tr><th>Run</th><th>Duration (h)</th><th>Status</th><th>Start</th><th>Stop</th></tr>"

for run in data:
    good_class = "good" if run["good_run_flag"] else "bad"
    good_text = "GOOD" if run["good_run_flag"] else "BAD"

    html += f"""
    <tr>
        <td><a href="#run{run['run_number']}">{run["run_number"]}</a></td>
        <td>{run["duration_h"]:.2f}</td>
        <td><span class="badge {good_class}">{good_text}</span></td>
        <td>{ts_to_str(run["start_time"])}</td>
        <td>{ts_to_str(run["stop_time"])}</td>
    </tr>
    """

html += "</table>"

# ===== 詳細表示 =====
for run in data:

    detectors = topology_to_detector_names(run.get("topology","{}"))

    html += f'<div class="run-card" id="run{run["run_number"]}">'
    html += f'<h2>Run {run["run_number"]}</h2>'

    html += "<p><b>Detectors:</b> "
    for d in detectors:
        html += f'<span class="badge detector">{d}</span>'
    html += "</p>"

    xml_config_name=os.path.basename(run["xml_config"])
    html += f"""
    <p><b>Name:</b> <span class="path">{run["name"]}</span></p>
    <p><b>Run Folder:</b> <span class="path">{run["run_folder"]}</span></p>
    <p><b>XML Config:</b> <span class="path">{xml_config_name}</span></p>
    """

    html += "<details><summary><b>Raw Files</b></summary><ul>"

    for k, v in run["raw_files"].items():
        filename = os.path.basename(v)
        html += f'''
        <li>
            DIF {k} :
            <span class="file" title="{v}">{filename}</span>
        </li>
        '''

    html += "</ul></details>"
    html += "</div>"

html += "</body></html>"

with open("/hsm/nu/wagasci/wg_auto_process/monitor/wagascidb_view.html", "w", encoding="utf-8") as f:
    f.write(html)

print("wagascidb_view.html を作成しました")

plot_run_timeline(data)