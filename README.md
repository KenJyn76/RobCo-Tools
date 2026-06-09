# RobCo-Tools
A set of experimental xEdit Scripts that generate RobCo Patcher ini files from esp/esl plugins.


-----------------------------------------------------------------------------------------------------------

The only tools in this collection I can personally confirm work are the List-based scripts, as they are the only ones I have used in my load order. These are at the top of the list. 

Load xEdit > Apply Script... > RobCo Tools

A dialog box will pop up and guide you through the process. The script will extract all data in the loaded plugins and generate RobCo Patcher ini files that you can then use as a template to add/remove what you want. The script will remove items that are removed from the LVLI record, and add items that are added. Optionally, the script can carry forward LVLOs that are identical to master.

The Export options *should* export all relevant data for that record type for the same purpose, but have not been tested to ensure syntax is always correct, since I have not used it. Empty filter lines included as none or null. Bug reports welcome. 

I made this to easily merge my Leveled Lists and Containers with RobCo Patcher, but since I'd already laid out the framework, included the other functions as well. These scripts are considered EXPERIMENTAL.
