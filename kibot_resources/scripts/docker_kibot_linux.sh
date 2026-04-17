#!/bin/sh

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
    -p 8000:8000 \
    --entrypoint /bin/bash \
    "$IMAGE" -c "
    if ! id $USER_NAME &>/dev/null; then
        echo \"Creating user $USER_NAME ($USER_ID:$GROUP_ID)...\"
        useradd -u $USER_ID -g $GROUP_ID -d /home/$USER_NAME -m $USER_NAME 2>/dev/null || true
    fi
    export HOME=/home/$USER_NAME
    cd \"$PROJECT_DIR\"
    exec bash -l"
