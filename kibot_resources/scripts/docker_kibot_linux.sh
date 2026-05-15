#!/bin/sh

# Launches the inti-cmnb KiCad/KiBot container for interactive use.
# Works with both Docker and rootless Podman (via the `docker` shim) — podman
# is auto-detected to add `--userns=keep-id` so bind-mounted home writes don't
# fail with EACCES. `/mnt/shared_data` is bind-mounted only when present, so
# hosts without it are unaffected. The project dir is mounted at the same
# path inside the container so relative paths in kibot_yaml/ resolve.

# Default image version
IMAGE="ghcr.io/inti-cmnb/kicad8_auto_full:dev"

# Parse the optional -v flag
while getopts "v:" opt; do
    case "$opt" in
        v)
            if [ "$OPTARG" = "9" ]; then
                IMAGE="ghcr.io/inti-cmnb/kicad9_auto_full:dev"
            else
                echo "Unsupported version: $OPTARG" >&2
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 [-v 9]" >&2
            exit 1
            ;;
    esac
done

export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
export USER_NAME=$(whoami)
PROJECT_DIR=$(pwd)

# Detect podman (invoked via the `docker` shim) so we can add --userns=keep-id,
# which maps container UIDs to host UIDs under rootless podman. Without it,
# writes to the bind-mounted home fail with EACCES.
USERNS_ARGS=""
if docker --version 2>&1 | grep -qi podman; then
    USERNS_ARGS="--userns=keep-id"
fi

# Mount the current project dir at the same path inside the container so
# relative paths (e.g. kibot_yaml/kibot_main.yaml) resolve correctly.
PROJECT_MOUNT=""
case "$PROJECT_DIR" in
    "/home/$USER_NAME"*) ;; # already under $HOME, no extra mount needed
    *) PROJECT_MOUNT="--volume=$PROJECT_DIR:$PROJECT_DIR:rw" ;;
esac

# The host's KiCad config (~/.config/kicad/*/sym-lib-table etc.) often uses
# symlinks into shared storage like /mnt/shared_data/kicad/libs. Bind-mount
# /mnt/shared_data when present so those symlinks resolve inside the container.
SHARED_MOUNT=""
if [ -d /mnt/shared_data ]; then
    SHARED_MOUNT="--volume=/mnt/shared_data:/mnt/shared_data:rw"
fi

docker run --rm -it \
    --user "$USER_ID:$GROUP_ID" \
    $USERNS_ARGS \
    --env NO_AT_BRIDGE=1 \
    --env DISPLAY="$DISPLAY" \
    --workdir="$PROJECT_DIR" \
    --volume=/tmp/.X11-unix:/tmp/.X11-unix \
    --volume="/etc/group:/etc/group:ro" \
    --volume="/etc/passwd:/etc/passwd:ro" \
    --volume="/etc/shadow:/etc/shadow:ro" \
    --volume="/home/$USER_NAME:/home/$USER_NAME:rw" \
    $PROJECT_MOUNT \
    $SHARED_MOUNT \
    -p 8000:8000 \
    --entrypoint /bin/bash \
    "$IMAGE" -c "
    if ! id $USER_NAME &>/dev/null; then
        echo \"Creating user $USER_NAME ($USER_ID:$GROUP_ID)...\"
        useradd -u $USER_ID -g $GROUP_ID -d /home/$USER_NAME -m $USER_NAME 2>/dev/null || true
    fi
    export HOME=/home/$USER_NAME
    # eeschema_do/pcbnew_do copy the system sym-lib-table/fp-lib-table into
    # the user's KiCad config on first run. Make sure the target dir exists
    # so that copy doesn't fail.
    mkdir -p \"\$HOME/.config/kicad/9.0\" \"\$HOME/.config/kicad/8.0\"
    # The KiCad image's normal entrypoint starts Xvfb so headless tools
    # (eeschema_do, pcbnew_do) can connect to a display. We override the
    # entrypoint to land in a shell, so we must launch Xvfb ourselves.
    if [ ! -e /tmp/.X99-lock ]; then
        Xvfb :99 -screen 0 1920x1080x24 -nolisten tcp >/dev/null 2>&1 &
        for i in 1 2 3 4 5; do
            [ -e /tmp/.X99-lock ] && break
            sleep 0.2
        done
    fi
    export DISPLAY=:99
    cd \"$PROJECT_DIR\"
    exec bash -l"
