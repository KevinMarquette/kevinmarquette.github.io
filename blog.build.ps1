Task Default UpdateTags, RecentPosts, Build

Task UpdateTags {
    .\UpdateTags.ps1
}

Task RecentPosts {
    .\UpdateRecentPosts.ps1
}

Task Build {
    docker run --rm -it --volume=$($PSScriptRoot):/srv/jekyll --name blogbuilder blog:build /bin/sh -c 'cd /srv/jekyll; bundle exec jekyll build --source /srv/jekyll/. --destination /srv/jekyll/_site/.'
}

Task Run Stop, Build, {
    'Starting container to host this site' 
    docker run --name bloghost --volume=$($PSScriptRoot)/_site:/usr/share/nginx/html:ro -d -p 8080:80 nginx
    'http://localhost:8080'
}

Task Stop {
    'Stopping container hosting blog on port 8080'
    docker rm bloghost -f
}
