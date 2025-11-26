/*
 * Preprocessing macro for arterial Aβ analysis
 *
 * This macro:
 *  1) Batch-processes multichannel .tif images in a folder
 *  2) Rescales each channel to a fixed intensity range and converts to 16‑bit
 *  3) Applies a CLIJ2-based background subtraction to the Aβ channel
 *  4) Saves the result as Adjusted_<original>.tif in an output folder
 *
 * All user‑editable parameters are in the SETTINGS section below.
 * There are no hidden options elsewhere in the code.
 *
 * Assumes 3‑channel images with:
 *   Channel 1 = α‑SMA (arteries)
 *   Channel 2 = e.g. CD31 or other
 *   Channel 3 = Aβ (background subtraction applied here)
 *
 * You can change this mapping in the SETTINGS if your data differ.
 */

/*** INPUT DIALOG (Fiji Script Parameters) ***/
#@ File   (label = "Input directory",   style = "directory") input
#@ File   (label = "Output directory",  style = "directory") output
#@ File   (label = "Relocate directory",style = "directory") relocate
#@ String (label = "File suffix",       value = ".tif")      suffix

/*************** SETTINGS (EDIT HERE IF NEEDED) ***************/

// Channel index (1‑based) for Aβ channel
abetaChannel = 3; 

// Intensity windows for each channel BEFORE converting to 16‑bit
// Order: [C1_min, C1_max, C2_min, C2_max, C3_min, C3_max]
c1_min = 0;   c1_max = 600;
c2_min = 0;   c2_max = 700;
c3_min = 0;   c3_max = 500;

// CLIJ2 difference of Gaussian parameters for Aβ channel
sigma1x = 1.0;
sigma1y = 1.0;
sigma1z = 0.0;
sigma2x = 5.0;
sigma2y = 5.0;
sigma2z = 0.0;

// CLIJ2 greyscale opening sphere radius (background estimate) for Aβ
radius_x = 50.0;
radius_y = 50.0;
radius_z = 1.0;

/***************** END OF SETTINGS ****************************/

setBatchMode(true);
processFolder(input);
print("Preprocessing complete!");
setBatchMode(false);

// Recursively walk through folders
function processFolder(inputDir) {
	list = getFileList(inputDir);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if (File.isDirectory(inputDir + File.separator + list[i])) {
			processFolder(inputDir + File.separator + list[i]);
		} else if (endsWith(list[i], suffix)) {
			processFile(inputDir, output, relocate, list[i]);
		}
	}
}

function processFile(inputDir, outputDir, relocateDir, file) {
	print("Processing: " + inputDir + File.separator + file);
	open(inputDir + File.separator + file);

	// Split channels
	run("Split Channels");
	imageTitles = getList("image.titles");

	// Rescale each channel and convert to 16‑bit
	for (j = 0; j < imageTitles.length; j++) {
		title = imageTitles[j];
		selectWindow(title);
		if (indexOf(title, "C1-") == 0) {
			setMinAndMax(c1_min, c1_max);
		} else if (indexOf(title, "C2-") == 0) {
			setMinAndMax(c2_min, c2_max);
		} else if (indexOf(title, "C3-") == 0) {
			setMinAndMax(c3_min, c3_max);
		}
		run("16-bit");
	}

	// Apply CLIJ2 background subtraction ONLY to the Aβ channel
	run("CLIJ2 Macro Extensions", "cl_device=");
	abetaTitle = "C" + abetaChannel + "-" + File.nameWithoutExtension(file);
	selectWindow(abetaTitle);
	Ext.CLIJ2_push(abetaTitle);

	diffName   = "C" + abetaChannel + "_DoG_" + File.nameWithoutExtension(file);
	bgName     = "C" + abetaChannel + "_BG_"  + File.nameWithoutExtension(file);

	// Difference-of-Gaussian (feature enhancement)
	Ext.CLIJ2_differenceOfGaussian3D(abetaTitle, diffName,
		sigma1x, sigma1y, sigma1z,
		sigma2x, sigma2y, sigma2z);

	// Greyscale opening sphere (smooth background estimate)
	Ext.CLIJ2_greyscaleOpeningSphere(abetaTitle, bgName,
		radius_x, radius_y, radius_z);

	// Pull results back to ImageJ
	Ext.CLIJ2_pull(diffName);
	Ext.CLIJ2_pull(bgName);
	Ext.CLIJ2_clear();

	// Subtract background image from DoG image
	imageCalculator("Subtract create", diffName, bgName);

	// Clean up intermediate windows and rename result back to Aβ channel name
	selectWindow(bgName);   close();
	selectWindow(diffName); close();
	selectWindow(abetaTitle); close();

	selectWindow("Result of " + diffName);
	rename(abetaTitle);

	// Merge channels back into a composite in original order (assumes 3 channels)
	finalTitles = getList("image.titles");
	c1 = c2 = c3 = "";
	for (k = 0; k < finalTitles.length; k++) {
		t = finalTitles[k];
		if (indexOf(t, "C1-") == 0) c1 = t;
		if (indexOf(t, "C2-") == 0) c2 = t;
		if (indexOf(t, "C3-") == 0) c3 = t;
	}

	run("Merge Channels...", "c1="+c1+" c2="+c2+" c3="+c3+" create");

	// Save adjusted composite
	saveAs("Tiff", outputDir + File.separator + "Adjusted_" + file);

	// Move original file to relocate directory
	File.rename(inputDir + File.separator + file, relocateDir + File.separator + file);

	run("Close All");
	run("Collect Garbage");
}
