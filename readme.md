Alpine based graphite-web container
===================================

This container provides a small variant of only the graphite-web interface.
Its meant to be used only for the rendering graphs or providing aggregated json output

The dashboard part of graphite-web is currently mainly defunct.

How to use:
-----------

    docker run --link carbon -p 8000:8000 -v graphite-data:/data/graphite smurfynet/graphite-web