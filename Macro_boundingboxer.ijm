/*
 * 1st step threshold based on alphaSMA, add to ROI mngr
 * filter out small structures (<100um), enlarge alphaSMA (5um)
 * go to other channels, clear outside, threshold, add to ROImngr, rename to abeta or cd31
 * 
 * 
 * 
 * 
 * 
 */
 
 dir = getDirectory("Choose a Directory ");
dir2 = dir;
naming=File.getName(dir2);
prtb=File.getParent(dir2);
dirNotUsed= prtb+ File.separator +naming+ File.separator +"M1 Not used";
dirProcessed= prtb+ File.separator +naming+ File.separator +"M1 Processed images";
dirROIs=prtb+ File.separator +naming+ File.separator +"M1 ROIs";

dirResults=dir+"M2 Results/";
dirROIextra=dir+"M2 ROIs/";

Dialog.create("Channels!");
Dialog.addMessage("!!!  CLIJ2 plugin required   !!!");

Dialog.addCheckbox("Do you want to generate .csv files?", true);

Dialog.addNumber("Threshold to detect aSMA?", 37);
Dialog.addNumber("Threshold to detect the other stuff?", 40);
Dialog.addNumber("Threshold to detect the other stuff?", 45);
Dialog.show();

//this part of the code stores the variables from the dialog window 

m2er=Dialog.getCheckbox();

thrshld=Dialog.getNumber();
stuffthrshld=Dialog.getNumber();
stuffthrshld2=Dialog.getNumber();

//creates folders for general directories if they're not already present
if (File.exists(dirNotUsed)==false) File.makeDirectory(dirNotUsed);
if (File.exists(dirProcessed)==false) File.makeDirectory(dirProcessed);
if (File.exists(dirROIs)==false) File.makeDirectory(dirROIs);
if (File.exists(dirResults)==false) File.makeDirectory(dirResults);
if (File.exists(dirROIextra)==false) File.makeDirectory(dirROIextra);

//resets everything in case something was open
roiManager("Deselect");
	roiManager("Reset");
	run("Select None");
	run("Clear Results");
	run("Close All");
count = 0;

countFiles(dir);
//
n = 0;

setBatchMode(false);
processFiles(dir);


print("M1 done!");

if (m2er==true) M2(dir);

function countFiles(dir) {
		namm=File.getName(dir);
	      list = getFileList(dir);
	      for (i=0; i<list.length; i++) {
	          if (endsWith(list[i], "/"))

             	countFiles(""+dir+list[i]);
	          else
	              count++;
	      }
}


function processFiles(dir) {
      list = getFileList(dir);
      for (i=0; i<list.length; i++) {
         // if (endsWith(list[i], "/")){
          //    processFiles(""+dir+list[i]);
         // }
         proc=false;
          if (endsWith(list[i], ".tif")) {   
          	bio=false;
          	proc=true;
          	}
		if (endsWith(list[i], ".czi")){
			bio=true;
			proc=true;
		}
	
          	parnt=File.getParent(dir);
          	Bcode=File.getName(dir);
            showProgress(n++, count); 
              
           			path = dir+list[i];
					if (proc==true)ROIrelocateFiles(path);
         }
}

function ROIrelocateFiles(path) {
	prnt=File.getParent(path);
	
	if (bio==false) {	
		open(path);
		//run("8-bit");
	}
	if (bio==true) {	
		run("Bio-Formats Importer", "open=["+path+"] color_mode=Grayscale open_all_series view=Hyperstack stack_order=XYCZT");
		//run("8-bit");
	}

	
	if (bitDepth()==16) bits=true;
	
	if (bitDepth()==8) bits=false;
	
	getDimensions(width0, height0, channels0, slices0, frames0);
	chan0=newArray(channels0);
	original=getTitle();
	name=File.getNameWithoutExtension(path);
	
	foldnam=name;
	filenam=File.getName(path);
	
	rename(name);
	selectWindow(name);
	

	//Ask the user to create the Slice ROI
	
	number=0;
		
		
	selectWindow(name);
	run("Duplicate...", "duplicate");
	rename("orig");
	
	run("Z Project...", "projection=[Max Intensity]");
	selectWindow(name);
	run("Close");
	selectWindow("MAX_orig");
	rename(name);
	selectWindow(name);
	run("Duplicate...", "duplicate channels=1");
	rename(name+"-1");
	selectWindow(name);
	run("Duplicate...", "duplicate channels=2");
	rename(name+"-2");
	selectWindow(name);
	run("Duplicate...", "duplicate channels=3");
	rename(name+"-3");
			

		
	roiManager("Deselect");
	run("Select None");
		
	roiManager("deselect");
	run("Select None");
	number=roiManager("count");			
	selectWindow(name+"-1");			
				
	setThreshold(thrshld, 255);
				//run("Convert to Mask");
			
	run("Create Selection");
			//if (selectionType() == -1) cont==false;

	
	if (selectionType() != -1){
		roiManager("add");
		number=roiManager("count");
		if (selectionType() == 9){		
			roiManager("split");	
			roiManager("Select", number-1);
			roiManager("delete");
					
			allplaques=number-1;
			number=roiManager("count");
		}	 
	}
	number=roiManager("count");
	totroi=number;
	xii=totroi-1;
			//for loop to iterate through roimgr to eliminate small sized rois in plaque channel?
			//Stack.setDisplayMode("grayscale");
	
		
	
		
	for(xii=totroi-1; xii>=0; xii--){
		roiManager("Select", xii);
		roiManager("Measure");
		Area=getResult("Area");
		run("Clear Results");
		if (Area<200) { //change minimum size
					//change to measure in pixels for this?
			roiManager("Delete");
		}
					/*if (Area>150) { //change maximum size
					//change to measure in pixels for this?
					roiManager("Delete");
					}*/
	}
				
			
	aSMAnumber=roiManager("count");
	if (aSMAnumber>0) {	
	for(xiii=aSMAnumber-1; xiii>=0; xiii--){
		roiManager("Select", xiii);
		run("Enlarge...", "enlarge=5");
		run("Enlarge...", "enlarge=-5"); //if you want to make the ROI fit perfectly around aSMA, otherwise delete this line
		roiManager("add");
		roiManager("Select", xiii);
		roiManager("Delete");
	}
			aSMAr=roiManager("count");
		for(xv=aSMAr-1; xv>=0; xv--){
		roiManager("Select", xv);
		Dialog.create("delete roi?");
		Dialog.addCheckbox("Delete this selection?", true);
		Dialog.show()
		nucdelete=Dialog.getCheckbox();

		if (nucdelete==true){
			roiManager("Select",xv);
			roiManager("Delete");
		}
		}
		//Jan 2024 addition of bounding boxer code
		//This code aims to segment arterioles based on CD31 using the aSMA bounding box as a template
		//
		//here I need to ask the user if there are any ROIs that should be combined, if so, select and press ok roiManager("combine") continue ==false
		//if continue == false waitforuser do you want to combine more ROIs (yes continue== false, no continue == true)
		//else save ROIs in M1 aSMA ROI folder, loop from 0 to number of ROIs in ROI manager, duplicate aSMA pic, rename aSMAboxr, select ROI, 
		//clear outside, get bounding box, duplicate cd31 pic, rename cd31boxr, draw rectangle w/bounding box coordinates, clear outside, deselect
		//threshold create selection add to roiManager rename to cd31_whatever, select aSMAboxr close, select cd31boxr close, restart loop
		//when loop is done, select original aSMA ROIs and delete
		//
		//
		//
		
		Dialog.create("");
		Dialog.addCheckbox("do you want to combine ROIs?", true);
		Dialog.show();
		combiner=Dialog.getCheckbox();
		if (combiner == true) {
waitForUser("Please, combine and add ROIs and delete the original ROIs");

		
		}
		
	aSMArs=roiManager("count");
	
	
		for(xvi=0; xvi<=aSMArs-1; xvi++){
			
		run("Select None");
		roiManager("Deselect");
			selectWindow(name+"-1");
		run("Duplicate...", "duplicate");
			rename("aSMAboxr");
			
			roiManager("Select", xvi);
			
			

			// bounding box
			run("Set Measurements...", "area mean bounding integrated skewness area_fraction redirect=None decimal=3");
			run("Measure");
			
			
				BBx=getResult("BX");
				BBy=getResult("BY");
				BBw=getResult("Width");
				BBh=getResult("Height");
				run("Clear Results");
				
				
				
				run("Select None");
				roiManager("Deselect");
		
				selectWindow(name+"-2");
				run("Duplicate...", "duplicate");
				rename("CD31boxr");
				selectWindow("CD31boxr");
				imageCalculator("Add create", "aSMAboxr", "CD31boxr");
				rename("boxr");
				selectWindow("aSMAboxr");
				close();
				selectWindow("CD31boxr");
				close();
				selectWindow("boxr");
				makeRectangle(BBx, BBy, BBw, BBh);
		
				run("Clear Outside");
				run("Select None");
				roiManager("Deselect");
				
				
				setThreshold(stuffthrshld, 255);
		run("Create Selection");
		if (selectionType() != -1){
			roiManager("add");
			cdcntr=roiManager("count");
			roiManager("select", cdcntr-1);
			roiManager("rename", "ROI_"+xvi+"_BBCD31aSMA");
		}
		selectWindow("boxr");
				close();
		roiManager("Deselect");
		run("Select None");
				
			
			
			
		}
			for(xvii=aSMArs-1; xvii>=0; xvii--){
				
		run("Select None");
		roiManager("Deselect");
					
			roiManager("Select", xvii);
			roiManager("delete");
			}
		
	
		//
		//
		//end of bounding boxer code
		//
		//
		//
		
		
		aSMAtotal=roiManager("count");
			if (aSMAtotal>0) {	
	
	for(xiv=0; xiv<=aSMAtotal-1; xiv++){	
		roiManager("Select", xiv);
		roiManager("rename", "ROI_"+xiv);
		roiManager("Deselect");
		run("Select None");
		selectWindow(name+"-1");
		run("Duplicate...", "duplicate");
		rename("aSMA");
		selectWindow(name+"-2");
		run("Duplicate...", "duplicate");
		rename("cd31");
		selectWindow(name+"-3");	
		run("Duplicate...", "duplicate");
		rename("abeta");
		
		selectWindow("aSMA");
		roiManager("Select", xiv);
		run("Clear Outside");
		roiManager("Deselect");
		run("Select None");
		setThreshold(thrshld, 255);
		
		run("Create Selection");
		if (selectionType() != -1){
			roiManager("add");
			cd31cntr=roiManager("count");
			roiManager("select", cd31cntr-1);
			roiManager("rename", "ROI_"+xiv+"_aSMA");
		}
		
		selectWindow("cd31");
		roiManager("Select", xiv);
		run("Clear Outside");
		roiManager("Deselect");
		run("Select None");
		setThreshold(stuffthrshld, 255);
		
		run("Create Selection");
		if (selectionType() != -1){
			roiManager("add");
			cd31cntr=roiManager("count");
			roiManager("select", cd31cntr-1);
			roiManager("rename", "ROI_"+xiv+"_CD31");
		}
		roiManager("Deselect");
		run("Select None");
		selectWindow("abeta");
		roiManager("Select", xiv);
		run("Clear Outside");
		roiManager("Deselect");
		run("Select None");
		setThreshold(stuffthrshld2, 255);
		run("Create Selection");
		if (selectionType() != -1){
			roiManager("add");
			cd31cntr=roiManager("count");
			roiManager("select", cd31cntr-1);
			roiManager("rename", "ROI_"+xiv+"_Abeta");
		}
				roiManager("Deselect");
		run("Select None");
		selectWindow("aSMA");
		run("Close");
		selectWindow("cd31");
		run("Close");
		selectWindow("abeta");
		run("Close");
		}
				
			
	
	
			
	
	roiManager("save", dirROIs+ File.separator +name+".zip");
	roiManager("Deselect");
	roiManager("Reset");
	}
	}
	run("Select None");
	run("Clear Results");
	run("Collect Garbage");
		
	//Move images to the folder M1 Processed images/

	selectWindow("orig");
	if (File.exists(dirProcessed+"/")==false) File.makeDirectory(dirProcessed+"/");
	File.rename(path,  dirProcessed+ File.separator +filenam); //saveAs("tiff", dirProcessed+ File.separator +foldnam+ File.separator +name+".tif"); use this version if you want to save a modified version of the image
	run("Close All");
			/*
			 * use this code if you want to save a modified version of the image so you keep the original image in the "not used folder"
			if (File.exists(dirNotUsed+ File.separator +foldnam+"/")==false) File.makeDirectory(dirNotUsed+ File.separator +foldnam+"/")
			File.rename(path, dirNotUsed+ File.separator +foldnam+ File.separator +filenam);
			roiManager("Deselect");
			roiManager("reset");
			*/
		
	//Move images without cells to the folder M1 Not used/
	
}





function M2(dir){
	setBatchMode(true);
run("Set Measurements...", "area mean integrated redirect=None decimal=3");
ROIsfolders=getFileList(dirROIs);
for (i=0; i<ROIsfolders.length; i++){
	//Read ROIs folder
		
		 //Get group folder and name
		 sizefoldName= lengthOf(ROIsfolders[i]);
		 groupNm=substring(ROIsfolders[i], sizefoldName-3, sizefoldName-1);
		 groupName=substring(ROIsfolders[i], 0, sizefoldName-4);
		 //Go inside Group folders
		

	//tablearray=newArray("Cell#", "ROIname", "TDPval", "LGMNval", "DAPIval");
	tablearray=newArray("ROIname", "Stuff intensity", "Area", "IntDen","RawIntDen");
	tablecreator (groupName+"Results", tablearray); 


				 
				 ROIFiles=getFileList(dirROIs+ROIsfolders[i]);
				 //Open image
					imaFileop=dirProcessed+ File.separator +groupName+".tif";
					
					open(imaFileop);
					//Get image parameters
					name=getTitle();
					rename("stack");
					
					maxThrs=pow(2,bitDepth());
					run("Z Project...", "projection=[Max Intensity]");
					rename(name);
					selectWindow("stack");
					run("Close");
					getDimensions(width, height, channels, slices, frames);
					getPixelSize(unit, pixelWidth, pixelHeight);
					width=width*pixelWidth;
					roiManager("Reset");
				roiManager("Open", dirROIs+ File.separator +groupName+".zip");
				 
				 
				//Duplicate the channel used to create the cell ROI and name the Duplicated image "Chan"
				run("Select None");
				selectWindow(name);
				run("Duplicate...", "duplicate");
				rename("Orig");
				
				
				
				//Close original image
				selectWindow(name);
				run("Close");
	
				//Get information of the ROIs
				roiManager("List");
				run("Clear Results");
				number=roiManager("count");
				//cellnr=1;
				for(xtr=0;xtr<number;xtr++){
					
					selectWindow("Orig");
					Stack.setChannel(1);
					//if(xtr>0)Stack.setChannel(xtr);
					roiManager("Select", xtr);
					run("Measure");
					artdp=getResult("Area",0);
					meanintenstdp=getResult("Mean",0);
					intden=getResult("IntDen",0);
					rawintden=getResult("RawIntDen",0);
					run("Clear Results");
					
				
					rname=getInfo("selection.name")+"aSMA";
					
					
tablearray=newArray(rname, meanintenstdp, artdp, intden, rawintden); //leftover from marvins macro tablearray=newArray(rname, meanintenstdp, meanintenslgmn, meanintensnuc);
tableprinter(groupName+"Results", tablearray);
selectWindow("Orig");
Stack.setChannel(2);
					//if(xtr>0)Stack.setChannel(xtr);
					roiManager("Select", xtr);
					run("Measure");
					artdp=getResult("Area",0);
					meanintenstdp=getResult("Mean",0);
					intden=getResult("IntDen",0);
					rawintden=getResult("RawIntDen",0);
					run("Clear Results");
					
				
					rname=getInfo("selection.name")+"CD31";
					
					
tablearray=newArray(rname, meanintenstdp, artdp, intden, rawintden); //leftover from marvins macro tablearray=newArray(rname, meanintenstdp, meanintenslgmn, meanintensnuc);
tableprinter(groupName+"Results", tablearray);
selectWindow("Orig");
Stack.setChannel(3);
					//if(xtr>0)Stack.setChannel(xtr);
					roiManager("Select", xtr);
					run("Measure");
					artdp=getResult("Area",0);
					meanintenstdp=getResult("Mean",0);
					intden=getResult("IntDen",0);
					rawintden=getResult("RawIntDen",0);
					run("Clear Results");
					
				
					rname=getInfo("selection.name")+"abeta";
					
					
tablearray=newArray(rname, meanintenstdp, artdp, intden, rawintden); //leftover from marvins macro tablearray=newArray(rname, meanintenstdp, meanintenslgmn, meanintensnuc);
tableprinter(groupName+"Results", tablearray);

					}
							
							
			savetab(groupName+"Results", dirResults+groupName);
			
			
		if (isOpen ("ROI Manager")){ 
			selectWindow("ROI Manager");
			roiManager("Reset");
		}
		if (isOpen ("Results")){ 
			selectWindow("Results");
			run("Close");
		}
		selectWindow(groupName+"Results");
		run("Close");
		run("Close All");

			run("Collect Garbage");
		
	}
print("M2 IS DONE!");				
}	
	
	
	
 
 function tablecreator(tabname, tablearray){
	run("New... ", "name=["+tabname+"] type=Table");
	headings=""+tablearray[0]+"";
	for (ll=1; ll<tablearray.length; ll++)headings=headings+"\t"+tablearray[ll];
	print ("["+tabname+"]", "\\Headings:"+ headings);
	
}

function tableprinter(tabname, tablearray){
	line=""+tablearray[0]+"";
	for (l=1; l<tablearray.length; l++) line=line+"\t"+tablearray[l];
	print ("["+tabname+"]", line);
	
}
function  savetab(tablename, dirRes){
	//tablename=getList("window.titles");
		selectWindow(tablename);
		 saveAs("Text", dirResults+groupName+".csv");
	}
	

/*
roiManager("reset");
run("Select None");
	run("Clear Results");
	run("Collect Garbage");

run("Close All");


*/