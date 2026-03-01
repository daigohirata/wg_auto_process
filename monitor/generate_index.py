import os
import subprocess
import shutil
from tinydb import TinyDB

BASE_LOCAL = "/hsm/nu/wagasci/wg_auto_process/monitor/data_quality/"
# BASE_REMOTE = "/hsm/nu/wagasci/data"
BASE_REMOTE = "/hsm/nu/wagasci/dhirata/data"

os.makedirs(BASE_LOCAL, exist_ok=True)

# ===== DB読み込み =====
db = TinyDB("/hsm/nu/wagasci/data/run15/database/wagascidb.db")
data = db.all()

# Run番号降順 → 最新5件
data = sorted(data, key=lambda r: r["run_number"], reverse=True)
latest_5 = data[:5]

# ===== 最新5Runのローカル名リスト =====
latest_dirnames = []
for run in latest_5:
    dirname = f"{run['name']}"
    latest_dirnames.append(dirname)

# ===== 古いディレクトリ削除 =====
for existing in os.listdir(BASE_LOCAL):
    full_path = os.path.join(BASE_LOCAL, existing)
    if os.path.isdir(full_path) and existing not in latest_dirnames:
        print(f"Removing old run directory: {existing}")
        shutil.rmtree(full_path)

# ===== rsyncで同期 =====
for run in latest_5:

    run_number = "15"  # 固定値
    run_name = run["name"]

    local_dirname = run_name
    local_path = os.path.join(BASE_LOCAL, local_dirname)

    remote_path = f"{BASE_REMOTE}/run{run_number}/{run_name}"

    # ===== 元ディレクトリ存在チェック =====
    if not os.path.exists(remote_path):
        print(f"WARNING: Remote path does not exist: {remote_path}")
        continue

    os.makedirs(local_path, exist_ok=True)

    print(f"Syncing {remote_path} -> {local_path}")

    result = subprocess.run([
        "rsync",
        "-av",
        "--delete",
        remote_path + "/",   # 末尾スラッシュ重要
        local_path
    ])

    if result.returncode != 0:
        print(f"ERROR: rsync failed for {run_name}")

DIF_LABELS = {
    0: "WallMRD North Top",
    1: "WallMRD North Bottom",
    2: "WallMRD South Top",
    3: "WallMRD South Bottom",
    4: "WAGASCI Upstream Top",
    5: "WAGASCI Upstream Side",
    6: "WAGASCI Downstream Top",
    7: "WAGASCI Downstream Side",
}

html = """
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Data Quality Viewer</title>
<style>
body { font-family: Arial; margin:40px; background:#f4f6f9;}
.run-block { background:white; padding:20px; margin-bottom:30px;
             box-shadow:0 4px 10px rgba(0,0,0,0.08); border-radius:8px;}
img { width:400px; margin:10px; }
.img-row { display:flex; flex-wrap:wrap; }
h1 {
    display: flex;
    align-items: center;
    gap: 20px;
}

.db-link {
    font-size: 0.6em;
    text-decoration: none;
    background: #3498db;
    color: white;
    padding: 6px 12px;
    border-radius: 6px;
}

.db-link:hover {
    background: #1f6fb2;
}
h3 {
    margin-top: 20px;
}
h4 {
    margin-top: 15px;
    font-size: 1em;
    color: #2c3e50;
}
details summary {
    font-weight: bold;
    cursor: pointer;
    margin-top: 10px;
}
.dif-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;   /* 2列 */
    gap: 20px;
    margin-bottom: 30px;
}

.dif-block {
    background: #fafafa;
    padding: 15px;
    border-radius: 6px;
    border: 1px solid #e0e0e0;
}

.dif-block h4 {
    margin-top: 0;
    font-size: 0.95em;
    color: #2c3e50;
}
.modal {
    display: none;
    position: fixed;
    z-index: 999;
    padding-top: 60px;
    left: 0;
    top: 0;
    width: 100%;
    height: 100%;
    overflow: auto;
    background-color: rgba(0,0,0,0.85);
}

.modal-content {
    display: block;
    margin: auto;
    width: auto;
    height: auto;
    max-width: 90vw;
    max-height: 90vh;
}

.close {
    position: absolute;
    top: 20px;
    right: 40px;
    color: white;
    font-size: 40px;
    font-weight: bold;
    cursor: pointer;
}
</style>
</head>
<body>
<h1>
  Data Quality (Latest 5 runs)
  <a href="wagascidb_view.html" class="db-link">[DB View]</a>
</h1>
"""

for run in latest_5:

    run_name = run["name"]
    run_number = run["run_number"]

    local_path = os.path.join(BASE_LOCAL, run_name)

    html += f'<div class="run-block">'
    html += f'<h2>Run {run_number} - {run_name}</h2>'

    # =========================
    # ADC
    # =========================
    adc_dir = os.path.join(local_path, "ADC")
    html += "<h3>ADC</h3>"
    html += '<div class="dif-grid">'

    for dif in range(8):

        label = DIF_LABELS[dif]

        html += '<div class="dif-block">'
        html += f'<h4>DIF{dif}: {label}</h4>'
        html += '<div class="img-row">'

        chip_images = []

        if os.path.exists(adc_dir):

            for f in sorted(os.listdir(adc_dir)):

                if f"DIF{dif}" not in f:
                    continue

                rel_path = f"data_quality/{run_name}/ADC/{f}"

                if "CHIP" not in f:
                    html += f'<img src="{rel_path}">'
                else:
                    chip_images.append(rel_path)

        html += "</div>"

        if chip_images:
            html += "<details>"
            html += "<summary>CHIP plots</summary>"
            html += '<div class="img-row">'
            for img in chip_images:
                html += f'<img src="{img}">'
            html += "</div></details>"

        html += "</div>"  # dif-block

    html += "</div>"  # dif-grid

    # =========================
    # BCID
    # =========================
    bcid_dir = os.path.join(local_path, "BCID")
    html += "<h3>BCID</h3>"
    html += '<div class="dif-grid">'

    for dif in range(8):

        label = DIF_LABELS[dif]

        html += '<div class="dif-block">'
        html += f'<h4>DIF{dif}: {label}</h4>'
        html += '<div class="img-row">'

        chip_images = []

        if os.path.exists(bcid_dir):

            for f in sorted(os.listdir(bcid_dir)):

                if f"DIF{dif}" not in f:
                    continue

                rel_path = f"data_quality/{run_name}/BCID/{f}"

                if "CHIP" not in f:
                    html += f'<img src="{rel_path}">'
                else:
                    chip_images.append(rel_path)

        html += "</div>"

        if chip_images:
            html += "<details>"
            html += "<summary>CHIP plots</summary>"
            html += '<div class="img-row">'
            for img in chip_images:
                html += f'<img src="{img}">'
            html += "</div></details>"

        html += "</div>"

    html += "</div>"
    html += "</div>"   # run-block

html += """<!-- Modal -->
<div id="imgModal" class="modal">
  <span class="close">&times;</span>
  <img class="modal-content" id="modalImg">
</div>

<script>
const modal = document.getElementById("imgModal");
const modalImg = document.getElementById("modalImg");

document.querySelectorAll("img").forEach(img => {
    img.onclick = function(){
        modal.style.display = "block";
        modalImg.src = this.src;
    }
});

modal.onclick = function(){
    modal.style.display = "none";
}
</script>
</body></html>"""

with open("/hsm/nu/wagasci/wg_auto_process/monitor/index.html", "w", encoding="utf-8") as f:
    f.write(html)

print("index.html generated.")