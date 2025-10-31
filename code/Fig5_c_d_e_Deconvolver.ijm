/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ File (label = "Relocate directory", style = "directory") relocate
//#@ File (label = "PSF", style = "directory") psfpath
#@ String (label = "File suffix", value = ".tif") suffix

setBatchMode(true);
processFolder(input);
print("Deconvolution complete!");
setBatchMode(false);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
	print("Processing: " + input + File.separator + file);


	open(input + File.separator + file);
	title = getTitle;
	origname=File.nameWithoutExtension;

	// Iterate over stack frames
	
		selectImage(title);

		run("Split Channels");
		cslice = getImageID();
Imagelist=getList("image.titles");

		
			selectWindow("C1"+"-"+title);
			setMinAndMax(0, 600);
			run("16-bit");
			
			selectWindow("C2"+"-"+title);
			setMinAndMax(0, 700);
			run("16-bit");
			
			selectWindow("C3"+"-"+title);
			setMinAndMax(0, 500);
			run("16-bit");
		
		
		run("CLIJ2 Macro Extensions", "cl_device=");

// Load image from disc 

image1 = "C3"+"-"+title;
Ext.CLIJ2_push(image1);
image2 = "C3diff-"+title;
image3 = "C3sphere-"+title;
// Difference Of Gaussian3D
sigma1x = 0.0;
sigma1y = 0.0;
sigma1z = 0.0;
sigma2x = 30.0;
sigma2y = 30.0;
sigma2z = 0.0;
Ext.CLIJ2_differenceOfGaussian3D(image1, image2, sigma1x, sigma1y, sigma1z, sigma2x, sigma2y, sigma2z);



// Greyscale Opening Sphere
radius_x = 50.0;
radius_y = 50.0;
radius_z = 1.0;
Ext.CLIJ2_greyscaleOpeningSphere(image1, image3, radius_x, radius_y, radius_z);
Ext.CLIJ2_release(image1);



// Subtract Images
Ext.CLIJ2_pull(image2);
Ext.CLIJ2_pull(image3);
Ext.CLIJ2_clear();

imageCalculator("Subtract create stack", "C3diff-"+title,"C3sphere-"+title);
selectWindow("C3sphere-"+title);
close();
selectWindow("C3diff-"+title);
close();
selectWindow("C3"+"-"+title);		
close();		
selectWindow("Result of C3diff-"+title);
rename("C3"+"-"+title);

		lst=getList("image.titles");
	
	
		 if (Imagelist.length == 1) run("Merge Channels...", "c1="+lst[0]+"");
		 if (Imagelist.length == 2) run("Merge Channels...", "c1="+lst[0]+" c2="+lst[1]+"");
		 if (Imagelist.length == 3) run("Merge Channels...", "c1="+lst[0]+" c3="+lst[1]+" c4="+lst[2]+"");
		 if (Imagelist.length == 4) run("Merge Channels...", "c1="+lst[0]+" c2="+lst[1]+" c3="+lst[2]+" c4="+lst[3]+"");
	
	saveAs("Tiff", output + File.separator + "Adjusted_" + file);
	
	File.rename(input + File.separator + file, relocate + File.separator +  file);
	run("Close All");

	run("Collect Garbage");
}
run("Close All");
run("Collect Garbage");