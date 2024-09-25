LIBNAME project8 '/home/u63751945/myfolders/week8';
/*1:Import the Bay Area House Price data set from the file '/folders/myfolders/Week8
/Bay Area House Price.csv’. Name the data set as house_price.*/
data house_price;
infile '/home/u63751945/myfolders/week8/Bay Area House Price.csv' DSD FIRSTOBS=2 delimiter=',';
input address $ info $ z_address $ bathrooms bedrooms finishedsqft lastsolddate :mmddyy10. lastsoldprice latitude longitude neighborhood $ totalrooms usecode $ yearbuilt zestimate zipcode zpid;
    format lastsolddate mmddyy10.;
run;

/*2:Drop the variables: address, info, z_address, neighborhood, latitude, longitude
, and zpid both using Data Statement and PROC SQL. Name the new data set as 
house_price.*/
data house_price_new;
    set house_price(drop=address info z_address neighborhood latitude longitude zpid);
run;
proc sql;
    create table house_price_new as
    select *
    from house_price(drop=address info z_address neighborhood latitude longitude zpid);
quit;

/*3:Add a new variable price_per_square_foot defined by lastsoldprice/finishedsqft
 both using Data Statement and PROC SQL*/
data house_price_new;
    set house_price(drop=address info z_address neighborhood latitude longitude zpid);
    price_per_square_foot = lastsoldprice / finishedsqft;
run;
proc sql;
    create table house_price_new as
    select *,
           lastsoldprice / finishedsqft as price_per_square_foot
    from house_price(drop=address info z_address neighborhood latitude longitude zpid);
quit;

/*4:Find the average of lastsoldprice by zipcode both using Data Statement and 
PROC SQL.*/
proc sort data=house_price_new;
    by zipcode;
run;

data house_price_avg;
    set house_price_new;
    by zipcode;
    retain sum_price count;
    if first.zipcode then do;
        sum_price = 0;
        count = 0;
    end;
    sum_price + lastsoldprice;
    count + 1;
    if last.zipcode then do;
        avg_price = sum_price / count;
        output;
    end;
    drop sum_price count;
run;
PROC SQL;
	create table house_price_avg as
	select *,
		avg (lastsoldprice) as avg_price
		from house_price_new
		group by zipcode;
quit;

/*5: Find the average of lastsoldprice by usecode, totalrooms, and bedrooms
 both using Data Statement and PROC SQL*/
proc sort data=house_price_new;
    by usecode totalrooms bedrooms;
run;

data house_price_avg;
    set house_price_new;
    by usecode totalrooms bedrooms;
    retain sum_price count;
    if first.usecode and first.totalrooms and first.bedrooms then do;
        sum_price = 0;
        count = 0;
    end;
    sum_price + lastsoldprice;
    count + 1;
    if last.usecode and last.totalrooms and last.bedrooms then do;
        avg_price = sum_price / count;
        output;
    end;
    drop sum_price count;
run;
proc sql;
    create table house_price_avg as
    select 
        usecode,
        totalrooms,
        bedrooms,
        mean(lastsoldprice) as avg_price
    from 
        house_price_new
    group by 
        usecode, totalrooms, bedrooms;
quit;

/*Plot the bar charts for bathrooms, bedrooms, usecode, totalrooms respectively,
 and save the bar chart of bedrooms as bedrooms.png.*/
/* Plot bar chart for bathrooms */
proc sgplot data=house_price_new;
    vbar bathrooms / datalabel;
    title 'Distribution of Bathrooms';
run;

/* Plot bar chart for bedrooms */
proc sgplot data=house_price_new;
    vbar bedrooms / datalabel;
    title 'Distribution of Bedrooms';
run;
/* Save the bar chart of bedrooms as bedrooms.png */
proc sgplot data=house_price_new;
    vbar bedrooms / datalabel;
    title 'Distribution of Bedrooms';
    ods graphics / imagename="bedrooms";
run;

/* Plot bar chart for usecode */
proc freq data=house_price_new;
    tables usecode / plots=freqplot;
    title 'Distribution of Use Code';
run;

/* Plot bar chart for totalrooms */
proc sgplot data=house_price_new;
    vbar totalrooms / datalabel;
    title 'Distribution of Total Rooms';
run;

/*7: Plot the Histogram, boxplot for lastsoldprice, zestimate respectively. 
Are they normal or skewed? What’s the median of the lastsoldprice? What’s the 
median of the zestimate?*/
/* Histogram for lastsoldprice */
PROC sgplot DATA=house_price_new;
histogram lastsoldprice;
TITLE "histogram for the lastsoldprice";
run;

/* Boxplot for lastsoldprice */
PROC sgplot DATA=house_price_new;
vbox lastsoldprice;
TITLE "boxplot for the lastsoldprice";
run;

/* Histogram for zestimate */
PROC sgplot DATA=house_price_new;
    histogram zestimate / fillattrs=(color=green);
    title 'Histogram of Zestimate';
run;

/* Boxplot for zestimate */
PROC sgplot DATA=house_price_new;
    vbox zestimate / fillattrs=(color=green);
    title 'boxplot of Zestimate';
run;

/*They are not normally distrubuted, they are right-skewed. 

/*8:Compare the average of zestimate for any two different zipcodes (You choose
 two different zipcodes). Do you agree that there is no difference between the 
 average zestimate in the two zipcodes statistically? Why?*/
PROC FREQ DATA=house_price_new;
	table zipcode;
RUN;

proc ttest data=house_price_new;
	where zipcode in (94102, 94103);
	class zipcode;
	var zestimate;
RUN;
/*There is difference in the average zestimates between the 2 zipcodes because
the p value is less than 0.05. */

/*9:Do you agree that there is no difference between the average zestimate and 
the average of lastsoldprice statistically? Why?*/
PROC ttest data=house_price_new;
	paired zestimate * lastsoldprice;
RUN;
/*Yes, because there is a difference between the zestimate and the lastsoldprice
because the p value is less than 0.01*/
/*10:Do you agree that the number of bedrooms is associated with the usecode? 
Why?*/
PROC FREQ DATA=house_price_new;
	table bedrooms * usecode / chisq;
RUN;
/*There is an association from this test because the p-value is less than 0.01*/

/*11:Do you agree that the number of bedrooms is associated with the number 
of bathrooms? Why?*/
PROC CORR DATA=house_price_new;
	var bedrooms  bathrooms;
RUN;
/*Yes there is an association because the p-value of the bathrooms is less than 0.01 */

/*12:Calculate the correlation coefficients of all numerical variables with 
the variable zesitmate, and plot the scatter plot and matrix.  (Hint: Use 
PLOTS(MAXPOINTS=none)=scatter in PROC CORR  so that the scatter graph is 
shown. Otherwise you may not see the graph because the data is very large.)*/
/* Calculate correlation coefficients */
PROC CORR DATA=house_price_new  plots(maxpoints=none)=scatter;
	with zestimate;
	var bathrooms bedrooms finishedsqft lastsoldprice totalrooms price_per_square_foot;
RUN;

/*13: Find a regression model for zestimate with the first three most correlated
variables.*/
PROC REG DATA=house_price_new plots(maxpoints=none);
	model zestimate = bathrooms finishedsqft lastsoldprice;
RUN;

/*14:Find a regression model for zestimate with the first five most correlated 
variables.*/
PROC REG DATA=house_price_new plots(maxpoints=none);
	model zestimate = bathrooms bedrooms finishedsqft lastsoldprice totalrooms;
RUN;

/*15:Compare the adjusted R^2 in the two models from question 13) and 14). The
 model that has a bigger adjusted R^2 is better.*/
/*Since 14) had 0.8328 as bigger adjusted R^2 is is better since the bigger R^2 is
better. */

/*16:Use the better model from question 15) to predict the house prices given 
the values of independent variables. (You name the values of independent 
variables for  4 houses)*/
PROC REG DATA=house_price_new plots(maxpoints=none);
	model zestimate = bathrooms bedrooms finishedsqft lastsoldprice totalrooms;
OUTPUT OUT = result predicted= q16;
RUN;

/*17:Export the predictive values from question 16) as an excel file named 
‘prediction.xlsx’*/
/*Exported file*/
/*18:Create a macro named average with two parameters category and price. In 
the macro, firstly use PROC MEANS for the data set house_price to calculate 
the mean of &price by &category. In the PROC MEANS, use option NOPRINT, and 
let OUT=averageprice. Then use PROC PRINT to print the data averageprice using 
the macro variables in the TITLE.*/
%MACRO average(category=,price=);
PROC MEANS DATA=house_price_new NOPRINT;
CLASS &category;
VAR &price;
output out=averageprice mean=mean;
RUN;
TITLE "average &price by &category";
PROC PRINT DATA= averageprice;
RUN;
%mend;

/*19:Call the macro %average(category=zipcode, price=price_per_square_foot).*/
%average(category=zipcode, price=price_per_square_foot);

/*20:Call the macro %average(category=totalrooms, price=zestimate).*/
%average(category=totalrooms, price=zestimate);