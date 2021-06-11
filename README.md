# Cycletourmap

Based on OpenStreetMap data a bicycle tour shall be visualized in a pleasing manner in the style of hand-drawn map of ye olde times: Only along the route/track the map shows details. Further away from the track only sparse information is given.

Implements a download from

- http://download.geofabrik.de/
- https://www.naturalearthdata.com/downloads/

# Usage

Configure `app/configuration/config.sh` with `_OSMDOWNLOADSGEOFABRIK` and `_POLYDOWNLOADSGEOFABRIK` to point to paths on [http://download.geofabrik.de/](http://download.geofabrik.de/)

Configure `app/configuration/config.sh` to set `_NATURALEARTHDOWNLOAD` to true.

Then run

```bash
app/bin/download.sh -v
```
