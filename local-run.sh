

 docker run \
  --name aaaaaaaaaaaaaa \
  --label aaaaa \
  --workdir /github/workspace \
  --rm \
  -e INPUT_FOLDER=MedalOverlay \
  -e INPUT_VERSION=1.0.0-snapshot \
  -e HOME=/github/home \
  -e GITHUB_REPOSITORY=camalot/chatbot-medaloverlay \
  -e GITHUB_REPOSITORY_OWNER=camalot \
  -e CI=true \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /home/rconr/Development/chatbot-medaloverlay:/github/workspace \
  cbgpa:local