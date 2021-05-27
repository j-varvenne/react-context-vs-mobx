#!/usr/bin/env bash
#
#   Utility script to start a local environment.
#
#   It is assumed that you have on the host:
#
#       - docker
#       - docker-compose
#       - Linux / MacOS environment (WSL might work but was untested)
#

display_usage() {
    echo ""
    echo "           \`8.\`8888.      ,8'   d888888o.   8 8888        8"
    echo "            \`8.\`8888.    ,8'  .\`8888:' \`88. 8 8888        8"
    echo "             \`8.\`8888.  ,8'   8.\`8888.   Y8 8 8888        8"
    echo "              \`8.\`8888.,8'    \`8.\`8888.     8 8888        8"
    echo "               \`8.\`88888'      \`8.\`8888.    8 8888        8"
    echo "               .88.\`8888.       \`8.\`8888.   8 8888        8"
    echo "              .8'\`8.\`8888.       \`8.\`8888.  8 8888888888888"
    echo "             .8'  \`8.\`8888.  8b   \`8.\`8888. 8 8888        8"
    echo "            .8'    \`8.\`8888. \`8b.  ;8.\`8888 8 8888        8"
    echo "           .8'      \`8.\`8888. \`Y8888P ,88P' 8 8888        8"
    echo ""
    echo ""
    echo "Usage:"
    echo "    ./x.sh start                Start webpack dev server."
    echo "    ./x.sh stop                 Stop webpack dev server."
    echo "    ./x.sh exec                 Exec in the container previously started with start. (useful to run command such as yarn lint)"
    echo "    ./x.sh logs [logs-opt]      Show the logs for the "
    echo "    ./x.sh build                Produce a production build."
    echo "    ./x.sh clean                Clean up folder from build artifacts."
    echo ""
    echo "Log Options:"
    echo ""
    echo "    --tail <number>            Number of lines to show from the end of the logs"
    echo "    -f                         Follow log output."
    echo ""

}

# ================================================
#   Default value
XSH_DEBUG_PORT_HOST=5879
XSH_DEBUG_PORT_CONTAINER=5859
XSH_WEBPACK_PORT=8032
XSH_USER_ID=$(id -u ${USER})
XSH_USER_GROUP=$(id -g ${USER})

# ================================================
#   Common Errors
ERROR_NOT_STARTED=$'Container not started. Use\n\n\t./x.sh start\n\nto start the container.'

# ================================================
#   Parse arguments

if [[ $# -eq 0 ]]
then
    echo "No argument provided"
    echo ""
    display_usage
    exit 1
fi

POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -h|--help)
        XSH_SHOW_HELP=1
        shift # past argument
        ;;
        start)
        XSH_START=1
        shift # past argument
        ;;
        stop)
        XSH_STOP=1
        shift # past argument
        ;;
        exec)
        XSH_EXEC=1
        FORWARD_ARGS=1
        shift # past argument
        ;;
        logs)
        XSH_LOGS=1
        FORWARD_ARGS=1
        shift # past argument
        ;;
        clean)
        XSH_CLEAN=1
        shift # past argument
        ;;
        build)
        XSH_BUILD=1
        shift # past argument
        ;;
        *)    # unknown option
        UNKNOWN_ARGUMENT="$1"
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac

    if [[ "$FORWARD_ARGS" == "1" ]]
    then
        # Consume remaining arguments
        while [[ $# -gt 0 ]]
        do
            POSITIONAL+=("$1")
            shift
        done
    fi
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ "${UNKNOWN_ARGUMENT}" != "" ]]
then
    echo "Unknown argument ${UNKNOWN_ARGUMENT}"
    exit 1
fi

if [[ "${SHOW_HELP}" != "" ]]
then
    display_usage
    exit 0
fi

# ================================================
# Process start command

if [[ "${XSH_START}" == "1" ]]
then
    if DOCKER_ID=$(cat docker/id 2>/dev/null); then
        docker rm -f $DOCKER_ID 2>/dev/null
        rm docker/id
    fi
    if DOCKER_ID=$(docker run -d --rm -it -v "$PWD:/app" -p $XSH_WEBPACK_PORT:$XSH_WEBPACK_PORT -p $XSH_DEBUG_PORT_HOST:$XSH_DEBUG_PORT_CONTAINER \
        -u $XSH_USER_ID:$XSH_USER_GROUP \
        --env "WEBPACK_PORT=$XSH_WEBPACK_PORT" \
        --env "NODE_ENV=development" \
        --workdir /app \
        node:lts yarn start); then
        echo $DOCKER_ID > docker/id
        docker logs -f --tail 10 $DOCKER_ID
        echo "Webpack dev server still running in background. Use `./x.sh stop` to stop it."
        exit 0
    else
        echo "Failed to start container"
        exit 1
    fi
fi

# ================================================
# Process exec command

XSH_EXEC_COMMAND=$@
if [[ "$XSH_EXEC_COMMAND" == "" ]]
then
    XSH_EXEC_COMMAND=$XSH_EXEC_DEFAULT_COMMAND
fi

exec_new_container_if_missing() {

    echo "Starting temporary container as webpack dev server not started."

    docker run --rm -it -v "$PWD:/app" -p $XSH_WEBPACK_PORT:$XSH_WEBPACK_PORT -p $XSH_DEBUG_PORT_HOST:$XSH_DEBUG_PORT_CONTAINER \
        -u $XSH_USER_ID:$XSH_USER_GROUP \
        --env "NODE_ENV=development" \
        --env "WEBPACK_PORT=$XSH_WEBPACK_PORT" \
        --workdir /app \
        node:lts $XSH_EXEC_COMMAND
}

if [[ "${XSH_EXEC}" == "1" ]]
then
    if DOCKER_ID=$(cat docker/id 2>/dev/null); then
        docker exec -it $DOCKER_ID $XSH_EXEC_COMMAND
        if [[ $? != 0 ]]
        then
            exec_new_container_if_missing
        fi
        exit 0
    else
        exec_new_container_if_missing
    fi
fi

# ================================================
# Process stop command

if [[ "${XSH_STOP}" == "1" ]]
then
    if DOCKER_ID=$(cat docker/id 2>/dev/null); then
        docker rm -f $DOCKER_ID
        exit $?
    else
        echo "$ERROR_NOT_STARTED"
        exit 1
    fi
fi

# ================================================
# Process clean command

if [[ "${XSH_CLEAN}" == "1" ]]
then
    echo "Cleaning up node_modules..." && docker run --rm -it -v "$PWD:/app" \
            --workdir /app \
            node:lts rm -rf node_modules/
    echo "Cleaning up dist..." && docker run --rm -it -v "$PWD:/app" \
            --workdir /app \
            node:lts rm -rf dist/
    if DOCKER_ID=$(cat docker/id 2>/dev/null); then
        echo "Stopping container if running..."
        docker rm -f $DOCKER_ID
        rm docker/id
        exit 0
    fi
fi

# ================================================
# Process build command

if [[ "${XSH_BUILD}" == "1" ]]
then
    docker run -d --rm -it -v "$PWD:/app" \
        --env "NODE_ENV=production" \
        --workdir /app \
        node:lts yarn run build
    exit $?
fi

# ================================================
# Process logs command

XSH_LOGS_COMMAND=$@
if [[ "$XSH_LOGS_COMMAND" == "" ]]
then
    XSH_LOGS_COMMAND="-f --tail 100"
fi

if [[ "${XSH_LOGS}" == "1" ]]
then
    if DOCKER_ID=$(cat docker/id 2>/dev/null); then
        docker logs $XSH_LOGS_COMMAND $DOCKER_ID
        exit $?
    else
        echo "$ERROR_NOT_STARTED"
        exit 1
    fi
fi