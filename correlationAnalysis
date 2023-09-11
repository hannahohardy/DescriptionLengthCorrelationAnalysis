import pandas as pd
import matplotlib.pyplot as plt
import nltk
import numpy as np
import io
import os
import re
import glob
from bs4 import BeautifulSoup
import html
from PIL import Image
import seaborn as sns
from wordcloud import WordCloud, STOPWORDS
import json
import boto3


#Imports Data from S3 bucket (from files right now) and into a DataFrame
def importData(bucketName):


    # Create an S3 client
    s3 = boto3.client('s3')
    csv_files = []


    
    # List all objects in the bucket
    response = s3.list_objects_v2(Bucket=bucketName)
    for obj in response.get('Contents', []):
        if obj['Key'].endswith('.csv'):
            csv_files.append(obj['Key'])
    
    print(csv_files)
    
    df = pd.DataFrame()
    # Append all files together (if multiple)
    for file in csv_files:
        s3_object = s3.get_object(Bucket=bucketName, Key=file)
        s3_data = s3_object['Body'].read().decode('utf-8')
        df_temp = pd.read_csv(io.StringIO(s3_data))
        df = df._append(df_temp, ignore_index=True)
    
    print(df)
    return df

#Modifications to dataframe
def dataFrameMods(df):


#CLEANING DESCRIPTION 
#correcting incorrect types in the description
    def fix_incorrect_types(value):
        if isinstance(value, (float, int)):
            return str(value)
        return value

# Apply the fix_incorrect_types function 
    df['description'] = df['description'].apply(fix_incorrect_types)

#scrape the description of html tags
    def remove_html_formatting(text):
     text = html.unescape(text)
     soup = BeautifulSoup(text, 'html.parser')
     return soup.get_text()


    df[['description']]=df[['description']].applymap(remove_html_formatting)

    #Correct types
    df['DescriptionLengthFull'] = pd.to_numeric(df['DescriptionLengthFull'])
    df['emailLeads'] = pd.to_numeric(df['emailLeads'])
    df['total_leads'] = pd.to_numeric(df['total_leads'])
    df['isModel'] = pd.to_numeric(df['isModel'])
    df['isfsbo'] = pd.to_numeric(df['isfsbo'])
    df['source_actual_date'] = pd.to_datetime(df['source_actual_date'])
    print(df.dtypes)

# IQR taking out outliers of the description length
# Calculate the upper and lower limits
    Q1 = df['DescriptionLengthFull'].quantile(0.25)
    Q3 = df['DescriptionLengthFull'].quantile(0.75)
    IQR = Q3 - Q1
    lower = Q1 - 1.5*IQR
    upper = Q3 + 1.5*IQR


# Create arrays of Boolean values indicating the outlier rows
    upper_array = np.where(df['DescriptionLengthFull']>=upper)[0]
    lower_array = np.where(df['DescriptionLengthFull']<=lower)[0]


# Removing the outliers
    df.drop(index=upper_array, inplace= True, axis= 0)
    df.drop(index=lower_array, inplace= True, axis= 0)


#Change condition to a numeric measure
    df.condition[df.condition == 'new'] =0
    df.condition[df.condition == 'used'] =1

    #the new modified df
    return df



#Builds some Dataframes that will be used for scatter plots and heat maps
def buildDF(df):

    dfmultivariate= df[['DescriptionLengthFull', 'emailLeads', 'condition', 'isModel', 'isfsbo']].copy()
    dfDLemails = df[['DescriptionLengthFull', 'emailLeads']].copy()
    dfDLtotals = df[['DescriptionLengthFull', 'total_leads']].copy()
    return dfmultivariate, dfDLemails, dfDLtotals

def correlations(dfDLemails, dfDLtotals):

# Calculate correlation
    #Total Leads vs Description Length
    DLtotalcorrP= dfDLtotals.corr(method='pearson')
    DLtotalcorrK= dfDLtotals.corr(method='kendall')
    DLtotalcorrS= dfDLtotals.corr(method='spearman')

    #Total Leads vs Description Length
    DLemailcorr= dfDLemails.corr() #this is Pearson
    DLemailcorrK= dfDLemails.corr(method='kendall')
    DLemailcorrS= dfDLemails.corr(method='spearman')

    print("Correlation Total Leads Pearsons: ", DLtotalcorrP)
    print("Correlation Total Leads Kendall: ", DLtotalcorrK)
    print("Correlation Total Leads Spearman: ", DLtotalcorrS)

    print("Correlation Email Leads Pearsons: ", DLemailcorr)
    print("Correlation Email Leads Kendall: ", DLemailcorrK)
    print("Correlation Email Leads Spearman: ", DLemailcorrS)
    
    return DLemailcorr

#S3 helper functions to save
def scatterplot_to_s3(df, bucketName, columnName, scatName): 
    filename = columnName + "scatterplot.png"
    plt.scatter(df['DescriptionLengthFull'], df[columnName])
    plt.xlabel('Description Length')
    plt.ylabel('Number of ' + scatName + ' Leads')

    scatterplot_image_path = "/tmp/" + filename  

    # Upload the scatterplot image to S3
    s3_client = boto3.client('s3')
    s3_client.upload_file(scatterplot_image_path, bucketName, filename)

def save_heatmap_to_s3(heatmap, bucketName, filename):
    heatmap_image_path = "/tmp/" + filename
    
    heatmap.figure.savefig(heatmap_image_path)
    plt.close()

    s3_client = boto3.client('s3')
    s3_client.upload_file(heatmap_image_path, bucketName, filename)


def save_to_bucket(wordcloud, bucketName, filename):
    filename = 'tmp/'+filename+'.png'
    s3_resource = boto3.resource('s3')
    object = s3_resource.Object(bucketName, filename)

    image_byte = image_to_byte_array(wordcloud.to_image())
    object.put(Body=image_byte)


def image_to_byte_array(image, format: str = 'png'):
    result = io.BytesIO()
    image.save(result, format=format)
    result = result.getvalue()

    return result

def save_dict_to_s3(wordcloud,bucketName,filename):
    filename = 'tmp/'+filename+'.txt'
    wcDict = wordcloud.words_
    dict_content = '\n'.join(f'{key}:{value}' for key, value in wcDict.items())
    s3_client = boto3.client('s3')
    s3_client.put_object(Body=dict_content, Bucket=bucketName, Key=filename)


def createWEmailLwordcloud(df):
#Word Cloud NLP
 
    comment_words = ''
    stopwords = set(STOPWORDS)
    
    # Check if any 'emailLeads' values are true
    if any(df['emailLeads']):
        for i in df['emailLeads']:
            # Iterate through the csv file
            for val in df.description:
                # Typecast each val to string
                val = str(val)
                # Split the value
                tokens = val.split()
                # Converts each token into lowercase
                for i in range(len(tokens)):
                    tokens[i] = tokens[i].lower()
                comment_words += " ".join(tokens) + " "
    
    wordcloud = WordCloud(
        width=800,
        height=800,
        background_color='black',
        colormap='GnBu_r',
        stopwords=stopwords,
        contour_width=1,
        min_font_size=10,
    ).generate(comment_words)
    
    # Plot the WordCloud image
    plt.figure(figsize=(8, 8), facecolor=None)
    plt.imshow(wordcloud, interpolation="bilinear")
    plt.axis("off")
    plt.tight_layout(pad=0)
    plt.show()
    return wordcloud

#doesn't just count entries that have email leads
#Counts all the in the df
def createCompletewordcloud(df):
#Word Cloud NLP
    comment_words = ''
    stopwords = set(STOPWORDS)
            # Iterate through the csv file
    for val in df.description:
                # Typecast each val to string
        val = str(val)
                # Split the value
        tokens = val.split()
                # Converts each token into lowercase
        for i in range(len(tokens)):
            tokens[i] = tokens[i].lower()
            comment_words += " ".join(tokens) + " "
    
    wordcloud = WordCloud(
        width=800,
        height=800,
        background_color='black',
        colormap='GnBu_r',
        stopwords=stopwords,
        contour_width=1,
        min_font_size=10,
    ).generate(comment_words)
    
    # Plot the WordCloud image
    plt.figure(figsize=(8, 8), facecolor=None)
    plt.imshow(wordcloud, interpolation="bilinear")
    plt.axis("off")
    plt.tight_layout(pad=0)
    plt.show()
    return wordcloud


#Produces the scatterplots
def scatterPlots(df, bucketName):
    # Scatterplot with total_leads
    scatterplot_to_s3(df, bucketName, 'total_leads', 'Total')

    # Scatterplot with emailLeads only
    scatterplot_to_s3(df, bucketName, 'emailLeads', 'Email')


#Produces the HeatMaps- portals included
def heatMaps(df, dfmultivariate, DLemailcorr,bucketName):
#heatmap emailsCorrelation
    plt.figure(figsize=(16, 6))
    heatmap = sns.heatmap(DLemailcorr, vmin=-1, vmax=1, annot=True, cmap='YlGnBu')# Give a title to the heatmap. Pad defines the distance of the title from the top of the heatmap.
    heatmap.set_title('Description Length to Email Leads Heatmap', fontdict={'fontsize':12}, pad=12)
    plt.show()
    save_heatmap_to_s3(heatmap, bucketName, 'emailleadsheatmap.png')

    #plt.savefig('emailsCorrelationheatmap.png', dpi=300, bbox_inches='tight')

## full heatmap with most of vars(not portals) 
    corr = dfmultivariate.corr()
    plt.figure(figsize=(16, 6))
    heatmap = sns.heatmap(corr, vmin=-1, vmax=1, annot=True, cmap='YlGnBu')
    # Give a title to the heatmap. Pad defines the distance of the title from the top of the heatmap.
    heatmap.set_title('Complete Anaylsis Heatmap', fontdict={'fontsize':12}, pad=12)
    plt.show()
    save_heatmap_to_s3(heatmap, bucketName, 'multivariateheatmap.png')

    #plt.savefig('multivariateheatmap.png', dpi=300, bbox_inches='tight')

#YachtWorld Heatmap
    dfYachtWorld= df[['DescriptionLengthFull', 'emailLeads', 'portal']].copy()
    dfYachtWorld = dfYachtWorld.loc[dfYachtWorld["portal"] ==  'YachtWorld']
    dfYachtWorld = dfYachtWorld.drop(columns="portal")
    
    corr = dfYachtWorld.corr()
    plt.figure(figsize=(16, 6))
    heatmap = sns.heatmap(corr, vmin=-1, vmax=1, annot=True, cmap='YlGnBu')# Give a title to the heatmap. Pad defines the distance of the title from the top of the heatmap.
    heatmap.set_title('YachtWorld Heatmap', fontdict={'fontsize':12}, pad=12)
    plt.show()
    save_heatmap_to_s3(heatmap, bucketName, 'YachtWorldheatmap.png')

    #plt.savefig('YachtWorldheatmap.png', dpi=300, bbox_inches='tight')

#boats.com Heatmap
    dfboatscom= df[['DescriptionLengthFull', 'emailLeads', 'portal']].copy()
    dfboatscom = dfboatscom.loc[dfboatscom["portal"] ==  'boats.com']
    dfboatscom = dfboatscom.drop(columns="portal")

    corr = dfboatscom.corr()
    plt.figure(figsize=(16, 6))
    heatmap = sns.heatmap(corr, vmin=-1, vmax=1, annot=True, cmap='YlGnBu')# Give a title to the heatmap. Pad defines the distance of the title from the top of the heatmap.
    heatmap.set_title('boats.com Heatmap', fontdict={'fontsize':12}, pad=12)
    plt.show()
    save_heatmap_to_s3(heatmap, bucketName, 'boatsComheatmap.png')



#'Boat Trader' Heatmap
    dfBoatTrader= df[['DescriptionLengthFull', 'emailLeads', 'portal']].copy()
    dfBoatTrader = dfBoatTrader.loc[dfBoatTrader["portal"] ==  'Boat Trader']
    dfBoatTrader = dfBoatTrader.drop(columns="portal")

    corr = dfBoatTrader.corr()
    plt.figure(figsize=(16, 6))
    heatmap = sns.heatmap(corr, vmin=-1, vmax=1, annot=True, cmap='YlGnBu')# Give a title to the heatmap. Pad defines the distance of the title from the top of the heatmap.
    heatmap.set_title('Boat Trader Heatmap', fontdict={'fontsize':12}, pad=12)
    plt.show()
    save_heatmap_to_s3(heatmap, bucketName, 'BoatTraderheatmap.png')


def descriptionLengthZero(df,bucketName):
    dLzero= df[['DescriptionLengthFull', 'source_actual_date', 'ID']].copy()
    #drops columns that aren't 0
    dLzero = dLzero[dLzero["DescriptionLengthFull"] ==  0]
    dLzero = dLzero.drop_duplicates(subset='ID')
    dLzero['source_actual_date'] = pd.to_datetime(dLzero['source_actual_date'])
    dLzero['Month'] = dLzero['source_actual_date'].dt.to_period('M')
    # Count zero entries per month
    monthly_counts = dLzero[dLzero["DescriptionLengthFull"] == 0].groupby('Month').size()

    # Set Seaborn style for the plot
    sns.set(style='whitegrid')

    # Convert Periods to strings for x-axis labels
    x_labels = [str(month) for month in monthly_counts.index]

    # Create a bar graph of zero entry counts per month
    plt.figure(figsize=(10, 6))
    plt.bar(x_labels, monthly_counts, color='blue')
    
    plt.xlabel('Month')
    plt.ylabel('Count of Zero Entries')
    plt.title('Count of Zero Description Length Entries per Month')
    plt.xticks(rotation=45)
    plt.tight_layout()

    plt.show()   

    # Save the plot image to BytesIO object
    image_buffer = io.BytesIO()
    plt.savefig(image_buffer, format='png')
    image_buffer.seek(0)

    # Upload the plot image to S3 using put_object
    s3_client = boto3.client('s3')
    s3_image_path = 'bar_plots/bar_plot.png'  # Change the S3 path as needed
    s3_client.put_object(Body=image_buffer, Bucket=bucketName, Key=s3_image_path, ContentType='image/png')

    plt.close()  # Close the plot to avoid displaying it in the console

 

def EmailLeadsWordCloud(df,bucketName):

#USING THE NEW FUNCTION:
    wordcloud = createWEmailLwordcloud(df)
    filename ='EmailLeadsWordCloud'

    # Save Word Cloud image to S3 bucket
    save_to_bucket(wordcloud, bucketName, filename)

    # Get and save Word Cloud dictionary content to S3
    save_dict_to_s3(wordcloud,bucketName,filename)

def isModelWordCloud(df,bucketName):
    #isModel Dataframes (only counting emailLeads)
    isModeldf= df[['description', 'emailLeads', 'isModel']].copy()
    isModeldf = isModeldf.loc[isModeldf["isModel"] == 1]#diff
    isModeldf = isModeldf.drop(columns="isModel")

    #Creating the isModelwithEmailLeadsWordCloud
    wordcloud = createWEmailLwordcloud(df)
    filename ='isModelwithEmailLeadsWordCloud'

    # Save Word Cloud image to S3 bucket
    save_to_bucket(wordcloud, bucketName, filename)
    # Get and save Word Cloud dictionary content to S3
    save_dict_to_s3(wordcloud,bucketName,filename)

    #Creating a Word Cloud that counts all isModel entries
    wordcloud = createCompletewordcloud(df)
    filename ='isModelWordCloud'

    # Save Word Cloud image to S3 bucket
    save_to_bucket(wordcloud, bucketName, filename)
    # Get and save Word Cloud dictionary content to S3
    save_dict_to_s3(wordcloud,bucketName,filename)
    
# isNotModel Wordcloud (counting emailLeads)
    isNotModeldf= df[['description', 'emailLeads', 'isModel']].copy()
    isNotModeldf = isNotModeldf.loc[isNotModeldf["isModel"] != 1]#diff
    isNotModeldf = isNotModeldf.drop(columns="isModel")

    #Creating the isModelwithEmailLeadsWordCloud
    wordcloud = createWEmailLwordcloud(df)
    filename ='isNotModelwithEmailLeadsWordCloud'

    # Save Word Cloud image to S3 bucket
    save_to_bucket(wordcloud, bucketName, filename)
    # Get and save Word Cloud dictionary content to S3
    save_dict_to_s3(wordcloud,bucketName,filename)

    #Creating a Word Cloud that counts all isModel entries
    wordcloud = createCompletewordcloud(df)
    filename ='isNotModelWordCloud'

    # Save Word Cloud image to S3 bucket
    save_to_bucket(wordcloud, bucketName, filename)
    # Get and save Word Cloud dictionary content to S3
    save_dict_to_s3(wordcloud,bucketName,filename)
    


def isfsboWordCloud(df, bucketName):
    isNotModeldf= df[['description', 'emailLeads', 'isfsbo']].copy()
    isNotModeldf = isNotModeldf.loc[isNotModeldf["isfsbo"] == 1]#diff
    isNotModeldf = isNotModeldf.drop(columns="isfsbo")
    #Creating the isModelwithEmailLeadsWordCloud
    wordcloud = createWEmailLwordcloud(df)
    filename ='isfsbowithEmailLeadsWordCloud'

    # Save Word Cloud image to S3 bucket
    save_to_bucket(wordcloud, bucketName, filename)
    # Get and save Word Cloud dictionary content to S3
    save_dict_to_s3(wordcloud,bucketName,filename)

    #Creating a Word Cloud that counts all isModel entries
    wordcloud = createCompletewordcloud(df)
    filename ='isfsboWordCloud'

    # Save Word Cloud image to S3 bucket
    save_to_bucket(wordcloud, bucketName, filename)
    # Get and save Word Cloud dictionary content to S3
    save_dict_to_s3(wordcloud,bucketName,filename)
    
# isNotModel Wordcloud (counting emailLeads)
    isNotModeldf= df[['description', 'emailLeads', 'isfsbo']].copy()
    isNotModeldf = isNotModeldf.loc[isNotModeldf["isfsbo"] != 1]#diff
    isNotModeldf = isNotModeldf.drop(columns="isfsbo")

    #Creating the isfsbowithEmailLeadsWordCloud
    wordcloud = createWEmailLwordcloud(df)
    filename ='isNotfsbowithEmailLeadsWordCloud'

    # Save Word Cloud image to S3 bucket
    save_to_bucket(wordcloud, bucketName, filename)
    # Get and save Word Cloud dictionary content to S3
    save_dict_to_s3(wordcloud,bucketName,filename)

    #Creating a Word Cloud that counts all isModel entries
    wordcloud = createCompletewordcloud(df)
    filename ='isNotfsboWordCloud'

    # Save Word Cloud image to S3 bucket
    save_to_bucket(wordcloud, bucketName, filename)
    # Get and save Word Cloud dictionary content to S3
    save_dict_to_s3(wordcloud,bucketName,filename)
    
 

def handler(): #add back in event, context
   
   # Create a session with boto3
    session= boto3.Session()

    bucketName = 'description-length-correlation-analysis-csv'
    #read this in 
    df = importData(bucketName)
    df= dataFrameMods(df)
    dfmultivariate, dfDLemails, dfDLtotals = buildDF(df)
    DLemailcorr= correlations(dfDLemails, dfDLtotals) 
    scatterPlots(df, bucketName)
    heatMaps( df, dfmultivariate, DLemailcorr,bucketName)
    descriptionLengthZero(df, bucketName)
    EmailLeadsWordCloud(df,bucketName)
    isModelWordCloud(df, bucketName)
    isfsboWordCloud(df, bucketName)



handler()

