/*
 * BoundingBoxer_ArterialAbeta.ijm
 *
 * Release-friendly macro for arterial Aβ analysis.
 *
 * This macro:
 *  1) Batch-processes multichannel .tif images in a folder
 *  2) Uses the α-SMA channel to detect arterial regions (ROIs)
 *  3) Filters out small ROIs by area
 *  4) Optionally enlarges the arterial ROIs
 *  5) Measures intensity statistics for each ROI in each channel
 *  6) Saves all results into a single CSV table
 *
 * All user-editable parameters are in the SETTINGS section below.
 * There are no hidden options elsewhere in the code.
 *
 * Assumes images are multichannel stacks with:
 *   Channel 1 = α-SMA (arteries)
 *   Channel 2 = (optional) CD31 / other marker
 *   Channel 3 = Aβ
 *
 * You can change channel indices and thresholds in the SETTINGS section.
 */

/*** INPUT DIALOG (Fiji Script Parameters) ***/
#@ File   (label = "Input directory",  style = "directory") input
#@ File   (label = "Output directory for CSV", style = "directory") outDir
#@ String (label = "File suffix",      value = ".tif")      suffix

/*************** SETTINGS (EDIT HERE IF NEEDED) ***************/

// Channel index (1-based) for α-SMA (artery marker)
alphaChannel = 1;

// Channels to measure (1-based indices).
// Example: measureChannels = newArray(1, 2, 3);   // measure SMA, CD31, Aβ
//          measureChannels = newArray(3);         // measure Aβ only
measureChannels = newArray(1, 3);

// Minimum arterial ROI area (in pixels^2) to keep
// ROIs smaller than this will be discarded.
minAreaPixels = 200;

// ROI expansion (dilation) in pixels (set to 0 to disable enlargement)
expandPixels = 3;

// Threshold method for α-SMA channel (e.g. "Otsu", "Default", "Moments", etc.)
alphaThresholdMethod = "Otsu";

// Measurement options: area, mean, min, max, integrated density
run("Set Measurements...", "area mean min max integrated redirect=None decimal=3");

/***************** END OF SETTINGS ****************************/

// Create results file path
resultsPath = outDir + File.separator + "BoundingBoxer_ArterialAbeta_results.csv";

setBatchMode(true);
clearResults();

// Write header line to results file (overwrites existing file)
header = "Image,ROI,Channel,ChannelIndex,Area,Mean,Min,Max,IntDen\n";
File.saveString(header, resultsPath);

// Process all files in folder (non-recursive)
fileList = getFileList(input.getPath());
fileList = Array.sort(fileList);

for (i = 0; i < fileList.length; i++) {
    if (endsWith(fileList[i], suffix)) {
        processFile(input.getPath(), fileList[i]);
    }
}

setBatchMode(false);
print("BoundingBoxer processing complete! Results saved to:");
print(resultsPath);

// ================== FUNCTIONS ===================== //

function processFile(inputDir, file) {
    path = inputDir + File.separator + file;
    print("\\nProcessing: " + path);
    open(path);

    // Remember the original image name (without extension)
    baseName = File.nameWithoutExtension(file);

    // Split channels into separate windows
    run("Split Channels");
    titles = getList("image.titles");

    // Find titles for each channel by prefix "C1-", "C2-", ...
    alphaTitle = "";
    channelTitles = newArray(titles.length);
    for (t = 0; t < titles.length; t++) {
        title = titles[t];
        channelTitles[t] = title;
        if (startsWith(title, "C" + alphaChannel + "-")) {
            alphaTitle = title;
        }
    }

    if (alphaTitle == "") {
        print("Warning: could not find alpha channel C" + alphaChannel + " in " + file + ". Skipping file.");
        closeAllImages();
        return;
    }

    // --------- STEP 1: Create arterial ROIs from α-SMA channel ---------- //

    selectWindow(alphaTitle);
    // Work on a duplicate to avoid modifying original channel
    run("Duplicate...", "title=Alpha_for_ROI");
    selectWindow("Alpha_for_ROI");

    // Threshold alpha channel
    setAutoThreshold(alphaThresholdMethod + " dark");
    setOption("BlackBackground", false);
    run("Convert to Mask");

    // Analyze particles to create ROIs
    roiManager("Reset");
    // size parameter is in pixel units by default; circularity 0-1
    run("Analyze Particles...", "size=" + minAreaPixels + "-Infinity show=Nothing add");

    roiCount = roiManager("Count");
    if (roiCount == 0) {
        print("  No arterial ROIs found in " + file + ". Skipping.");
        closeAllImages();
        return;
    }

    // Optionally expand ROIs
    if (expandPixels > 0) {
        roiManager("Select", newArray(0, roiCount-1)); // select all
        roiManager("Enlarge", expandPixels);
    }

    // Close temp alpha image
    close();

    // --------- STEP 2: Measure each ROI in selected channels ---------- //

    for (r = 0; r < roiManager("Count"); r++) {
        roiManager("Select", r);

        // For each channel in measureChannels, measure intensity
        for (m = 0; m < measureChannels.length; m++) {
            chIndex = measureChannels[m];
            chTitle = getChannelTitle(channelTitles, chIndex);

            if (chTitle == "") {
                print("  Warning: channel C" + chIndex + " not found in " + file + ". Skipping this channel.");
                continue;
            }

            selectWindow(chTitle);
            run("Measure");
            row = nResults - 1;

            // Add metadata columns
            setResult("Image",   row, baseName);
            setResult("ROI",     row, r + 1);
            setResult("Channel", row, chTitle);
            setResult("ChannelIndex", row, chIndex);
            updateResults();

            // Append this row to CSV
            line = getResult("Image", row) + "," +
                   getResult("ROI", row)   + "," +
                   getResult("Channel", row) + "," +
                   getResult("ChannelIndex", row) + "," +
                   getResult("Area", row)  + "," +
                   getResult("Mean", row)  + "," +
                   getResult("Min", row)   + "," +
                   getResult("Max", row)   + "," +
                   getResult("IntDen", row) + "\n";

            File.append(line, resultsPath);
        }
    }

    // Clear Results table for next image
    run("Clear Results");
    closeAllImages();
}

// Helper: get channel title from list of channelTitles
function getChannelTitle(channelTitles, chIndex) {
    prefix = "C" + chIndex + "-";
    for (i = 0; i < channelTitles.length; i++) {
        if (startsWith(channelTitles[i], prefix)) {
            return channelTitles[i];
        }
    }
    return "";
}

// Helper: close all open images for a clean state
function closeAllImages() {
    while (nImages > 0) {
        selectImage(nImages);
        close();
    }
}
