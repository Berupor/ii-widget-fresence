import {pixelsOfPpm, seedOf} from "ArtPalette.mjs";

WorkerScript.onMessage = ppm => WorkerScript.sendMessage(seedOf(pixelsOfPpm(ppm)));
