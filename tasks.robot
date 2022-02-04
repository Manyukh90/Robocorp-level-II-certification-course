*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Resource          ./_resources/settings.robot  
Resource          ./_resources/page_object/OrderPage.robot

Suite Teardown      Cleaup

*** Variables ***

${URL}=                 https://robotsparebinindustries.com/#/robot-order
${order_file_url}=      https://robotsparebinindustries.com/orders.csv

${receipt_dir}          ${OUTPUT_DIR}${/}receipts

*** Keywords ***
Collect CSV File From User
    [Documentation]    Request the order file URL from the user using an input dialog
    Add heading    Upload CSV File
    Add file input
    ...    label=Upload the CSV file with orders robot data
    ...    name=fileupload
    ...    file_type=CSV files (*.csv)
    ...    destination=${CURDIR}
    ${respone}=     Run Dialog
    [Return]        ${respone.fileupload}[0]

Success dialog
    Add icon      Success
    Add heading   Upload CSV File have been processed
    # Add files     *.txt
    Run dialog    title=Success       

Open the robot order website
    ${secret} =     Get Secret    urls
    Open Available Browser      ${secret}[order_page_url]
    Maximize Browser Window
    Set Selenium Speed          0.5
    Sleep                       5

Get orders
    [Documentation]    Download the order CSV file, read it into table
    [Arguments]             ${order_file_url}
    # RPA.HTTP.Download       ${order_file_url}       overwrite=true
    ${orders}=              Read table from CSV     ${order_file_url}
    [Return]                ${orders}    

Close the annoying modal
    Wait Until Element Is Visible     css:div.modal-content
    Click Button                    OK    

Fill and submit the form for one robot order
    [Arguments]         ${order_rep}
    Wait Until Element Is Visible     id:head
    Select From List By Value       head         ${order_rep}[Head]      
    Select Radio Button             body         ${order_rep}[Body]
    Input Text                      //html/body/div/div/div[1]/div/div[1]/form/div[3]/input      ${order_rep}[Legs]
    Input Text                      //html/body/div/div/div[1]/div/div[1]/form/div[4]/input      ${order_rep}[Address]

Preview the robot
    Click Button                    Preview

Submit the order
    Wait Until Element Is Visible       //html/body/div/div/div[1]/div/div[2]/div[2]/div/img[3]
    Click Button                        Order

Take a screenshot of the robot
    [Arguments]           ${order_number}
    Wait Until Element Is Visible               //html/body/div/div/div[1]/div/div[2]/div/div/img[3]
    Set Local Variable    ${file_path}          ${OUTPUT_DIR}${/}robot_preview_image_${order_number}.png
    Screenshot            id:robot-preview-image        ${file_path}   
    [Return]              ${file_path}

Store order receipt as PDF file
    [Arguments]             ${order_number}
    Wait Until Element Is Visible       id:receipt                           
    ${receipt_html}=        Get Element Attribute        id:receipt    outerHTML
    Set Local Variable      ${file_path}        ${receipt_dir}${/}receipt_${order_number}.pdf
    Html To Pdf             ${receipt_html}     ${file_path}
    [Return]                ${file_path}


Embed robot preview screenshot to receipt PDF file
    [Arguments]             ${file_path_screenshot}       ${file_path_pdf}
    Open Pdf                ${file_path_pdf}
    ${image_files}=         Create List         ${file_path_screenshot}:align=center
    Add Files To PDF        ${image_files}      ${file_path_pdf}      append=True
    Close Pdf               ${file_path_pdf}
    

Create receipt PDF with robot preview image
    [Arguments]         ${order_number}     ${screenshot}
    ${file_path_pdf}=   Store order receipt as PDF file         ${order_number}
    Embed robot preview screenshot to receipt PDF file          ${screenshot}    ${file_path_pdf}
        
Order new robot
    Click Button            Order another robot

Create ZIP file of all receipts
    ${zip_file_name} =          Set Variable        ${OUTPUT_DIR}${/}all_receipts.zip
    Archive Folder With Zip    ${receipt_dir}       ${zip_file_name}

Cleaup
    Remove File         orders.csv
    Close All Browsers
    
# ------------------------------------------------------------------------------


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${csv_file_path}=     Collect CSV File From User
    Success dialog
    Open the robot order website
    ${orders}=    Get orders    ${csv_file_path}
    FOR    ${order_rep}    IN    @{orders}
        Close the annoying modal
        Fill and submit the form for one robot order    ${order_rep}
        Preview the robot
        Submit the order
        ${screenshot}=      Take a screenshot of the robot      ${order_rep}[Order number]
        Create receipt PDF with robot preview image             ${order_rep}[Order number]    ${screenshot}
        Order new robot 
    END
    Create ZIP file of all receipts

