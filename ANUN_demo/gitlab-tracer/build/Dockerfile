FROM ubuntu:20.04

# install utilities
RUN apt-get update -y \
    && apt-get install -y curl netcat

RUN curl -s https://downloads.anun.cloud/tracer/pub/anun-installer.sh | bash -s -- -p "https://downloads.anun.cloud/tracer/anun-tracer.tar.gz?Expires=1686661359&Signature=tc6rt5dOkKmK6WEXLMxrNYRm2tmMCapOH6fdbbqoVBdNXtQ3l38zjNF-4eU4jvqDlfiQ9JkWEBdC23M~WhV8PU3RzPdys41yRapmWk1GidSR9XZ0aarqhm4nxUl6H1ajctX4pGup44bcFM9hCzTealdAHyXPdoS5qCqXYVK0doPIJqbK5PWs7pNd8cQGmTfnWIAPqKLhDsB9-9GYW7MPB5~FEup-u2dlBk8NwFG0fzXY2AEjRFQfet~-xOdQbkTvE8vCd3EDQYyvR085vrPL7Gw2H8sX01mGl2AriAZvg22uYhYQ3FUmlWOwrfU1h6cgFaX28pnKRseG7uQh7aSuKA__&Key-Pair-Id=K3I8ZP4ALY4308"
