pro extractROI

;this program utilizes ENVI ROIs and widgets in interactively select file and ROIs
;output is image data from ROIs formatted to the standards for input into Splus for binary decision tree
;written 1-17-01 by Kerry Halligan

;this file should be saved to the envi_sav directory.
;ENVI compiles all .pro and .sav files in the envi_sav directory at startup

;to extract ROI data and format for Splus begin by Starting envi
;load an image file, display image, create new ROIs for image or restore existing
;ROI file. then go to the IDL Developement Window, open up this IDL script, compile it, and run it.
;it will interactively ask for the image file that contains the data, the ROIs associated with that image
;file that you wish to use, and the output Splus compatible file to write.

;use the envi_select widget to select the image that contains the data, fid will be file id of the open file, pos will be the number of bands
envi_select, title=’Input Filename of Image’, fid=fid, pos=pos

;use envi_file_query to find out number of rows, samples, bands, byte order, and
;note interleave: 0= bsq, 1=bil, 2=bip
;note data type: 1=byt, 2=interger, 4=floating point (see progguid.pdf page 330 for more)
envi_file_query, fid, data_type=data_type, ns=ns, nl=nl, nb=nb, interleave=interleave

;use ENVI’s pickfile to enter the output filename
newfile = pickfile(title=’Enter output filename (*.txt)’)

;use roi_ids to retrieve all of the defined roi’s for the image
roi_ids = envi_get_roi_ids(fid=fid, roi_names=roi_names)
if (roi_ids[0] eq -1) then begin
print, ‘No regions associeated with the selected file’
return
endif

;build a compound widget for selecting the desired ROIs
base = widget_auto_base(title=’ROI Selection’)
wm = widget_multi(base, list=roi_names, uvalue=’list’, /auto)
result = auto_wid_mng(base)

;count is an output of the ROI selection widget that is the number of ROIs selected
;ptr is equal to count for all all valid lists (lists with value of 1 rather than -1)
ptr = where(result.list eq 1, count)

;determine the total number of ROI points and make an array that is nb x number of points
tot_pnts=intarr(count)
for i=0,count-1 do begin
roi_addr = envi_get_roi(roi_ids[i])
tot_pnts(i) = n_elements(roi_addr)
endfor
total_pnts = total(tot_pnts)
final_array = make_array(nb,total_pnts,type=data_type)

;begin the loops that retrieve all of the data by band for each ROI
;for each RIO
for i=0,count-1 do begin
;querry the ROI for the number of points
roi_addr = envi_get_roi(roi_ids[i])
points = n_elements(roi_addr)
;create a temp. array to store the band data for all that is nb by points
temp_array = make_array(nb,points,type=data_type)
;for each band of the image
for j=0, nb-1 do begin
;retrieve the image data for all points in the image
data = envi_get_roi_data(roi_ids[ptr[i]], fid=fid, pos=pos[j])
;fill columns with data for each band
temp_array(j,0 :points-1) = data(0 :points-1)
endfor
;copy values from temp_array to the appropriate cells of final_array
if (i ne 0) then begin
ystart = total(tot_pnts(0:i-1))
endif else begin
ystart = 0
endelse
yend = (total(tot_pnts(0:i))-1)
final_array(0:nb-1,ystart:yend) = temp_array
endfor
;open up newfile (from the pickfile in line 16) for writing call it unit 1
openw,3,newfile
;for each RIO begin the loop
for i=0,count-1 do begin
;querry for roi name
name = roi_names(i)
;querry the ROI for the number of points
roi_addr = envi_get_roi(roi_ids[i])
points = n_elements(roi_addr)
;establish the line in final_array to begin printing from
if (i ne 0) then begin
ystart = total(tot_pnts(0:i-1))
endif else begin
ystart = 0
endelse
for j=0,points-1 do begin
;build a print format statement using the nb variable
;for the number of bands to print data for, first variable is
;a string (roiname)
fs = ‘printf,3,FORMAT=”(1A,’ + string(nb) + $
‘F15.6)”,roi_names(i),final_array(0:nb-1,ystart+j)’
; execute the print string
r = execute(fs)
endfor
endfor
print,’ done ‘
close,3
return
end