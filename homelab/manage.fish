#!/usr/bin/env fish

cd (dirname (status filename))

set -l action

switch "$argv[1]"
    case up
        set action up -d
    case upp
        set action up -d --pull always
    case down
        set action down
    case '*'
        echo "kullanim: ./manage.fish up|upp|down"
        exit 1
end

for project in $(ls -d */)
    echo "== $project =="
    cd $project
    pass run --env-file ahu.env --env-file ../.env.global -- docker compose $action
    cd ..
end
