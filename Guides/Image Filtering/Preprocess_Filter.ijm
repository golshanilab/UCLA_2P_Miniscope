// This is a macro that allows the user to selectively filter any striping
// artifacts that may be present in their data, using a predefined "FFT Filter.tif"
// signal filter. Please note this will only function for images of size 512 x 512 and a 
// different "FFT Filter" will need to be generated for different image sizes. 

// Check if you have the filter open already
imageList = getList("image.titles");
filterTitle = "FFT_Filter.tif"; //Please find this on GitHub in Guides > Image Filtering 
filterIsOpen = false;

// If FFT_Filter is open
for (i = 0; i < imageList.length; i++) {
    if (imageList[i] == filterTitle) {
        filterIsOpen = true;
        break;
    }
}

// If FFT_Filter is not open, you should open it
if (!filterIsOpen) {
    openPath = File.openDialog("Please open 'FFT_Filter.tif'");
    if (openPath == "") exit("No file selected.");
    open(openPath);
    // Refresh the image list
    imageList = getList("image.titles");
}

// Show dialog to select stack and filter
Dialog.create("UCLA 2P Miniscope Artifact-Fixer 5000");
Dialog.addChoice("Images to Filter:", imageList, imageList[0]);
Dialog.addChoice("Filter:", imageList, filterTitle);
Dialog.show();

selectedStack = Dialog.getChoice();
selectedFilter = Dialog.getChoice();
selectWindow(selectedStack);
stackSize = nSlices;

if (stackSize > 1) {
    for (i = 1; i <= stackSize; i++) {
        setSlice(i);
        run("Custom Filter...", "filter=[" + selectedFilter + "]");
    }
} else {
    run("Custom Filter...", "filter=[" + selectedFilter + "]");
}

originalName = selectedStack;
rename(originalName + " FFT Filtered");

// Thank you for filtering your images! This is not a problem any more if you use our new wiring 
// schemes that increase the coaxial shielding (: 