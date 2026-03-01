# ~/.wagasci/.wagasci_ana_env.sh

#### ===== 共通設定 ===== ####
# Singularity/Apptainer 関連
export APPTAINER_PATH="/sw/packages/apptainer/latest/bin/apptainer"

# SIFファイル保存先
export WGANA_SIF_DIR="/hsm/nu/wagasci/container/sif_backup"

# キャッシュ関連 
export WGANA_CACHE_DIR="~/.apptainer/"
export APPTAINER_TMPDIR="${WGANA_CACHE_DIR}/tmp"
export APPTAINER_CACHEDIR="${WGANA_CACHE_DIR}"

# SIFファイルのパターン
export WGANA_SIF_PATTERN="wagasci_ana_*.*.*.sif"

# DockerHubのイメージ名
export WGANA_IMAGE_NAME="wgbm/wagasci_ana"


#### ===== 関数定義 ===== ####
# ---- コンテナ起動 ----
function wgAna() {
  # sifファイル一覧
  if [ "$1" = "--list" ]; then
    \ls -1 ${WGANA_SIF_DIR}/${WGANA_SIF_PATTERN} 2>/dev/null \
        | sed -E 's|.*/wagasci_ana_([0-9]+\.[0-9]+\.[0-9]+)\.sif|\1|' \
        | sort -V
    return 0
  fi

  # バージョン指定
  if [ "$1" = "--version" ]; then
    if [ -z "$2" ]; then
      echo "[Error]: Please specify a version (e.g., 1.2.3)."
      return 1
    fi
    version="$2"
    latest_sif="${WGANA_SIF_DIR}/wagasci_ana_${version}.sif"
    shift 2
    if [ ! -f "$latest_sif" ]; then
      echo "[Error]: Specified version not found: $latest_sif"
      return 1
    fi
  else
    if ! sif_files=$(\ls -1 ${WGANA_SIF_DIR}/${WGANA_SIF_PATTERN}); then
      echo "[Error]: Failed to list sif files in '${WGANA_SIF_DIR}'"
      return 1
    fi

    latest_sif=$(echo "$sif_files" \
        | grep -E 'wagasci_ana_[0-9]+\.[0-9]+\.[0-9]+\.sif$' \
        | sed -E 's|.*/wagasci_ana_([0-9]+\.[0-9]+\.[0-9]+)\.sif$|\1 \0|' \
        | sort -V \
        | tail -n 1 \
        | awk '{print $2}')
    [ -z "$latest_sif" ] && {
      echo "[Error]: No sif file found."
      return 1
    }
  fi

  # コマンド決定
  if [ -z "$1" ]; then
    echo "--> Starting a container ($latest_sif) with default shell"
    command="bash --noprofile --norc"
  else
    echo "--> Starting a container ($latest_sif)"
    command="$@"
  fi

  # 起動
  "${APPTAINER_PATH}" run \
    --bind /hsm/nu/wagasci/ \
    --bind /hsm/nu/ninja/ \
    --bind /group/nu/ninja/work/han/mc/e71a \
    --bind /group/t2k/beam \
    --bind /home/nu/dhirata/.wagasci/rootlogon.C:/opt/root/v6-30-08/etc/system.rootlogon.C \
    "${latest_sif}" \
    ${command}
}
