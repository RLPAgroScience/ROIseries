#---------------------------------#
# ROIseries "Wine Tasting" part 2 #
#---------------------------------#

# This is the second part of the Wine Tasting tutorial.
# Please refer to the first part to get more infos.

import ROIseries_feature_sommelier as RS_test

# Replace the following pathes with the pathes printed out at the end of the first part of the tutorial.
features_csv = [ 
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\R\\features\\R_features_2017-04-20T12-58-43.97203445434548Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\R\\features\\R_features_2017-04-20T12-58-44.09804463386513Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\R\\features\\R_features_2017-04-20T12-58-44.21604841947533Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\R\\features\\R_features_2017-04-20T12-58-44.33405220508553Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\G\\features\\G_features_2017-04-20T12-58-44.51304942369438Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\G\\features\\G_features_2017-04-20T12-58-44.61206316947914Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\G\\features\\G_features_2017-04-20T12-58-44.7210547327993Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\G\\features\\G_features_2017-04-20T12-58-44.83402937650658Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\B\\features\\B_features_2017-04-20T12-58-45.01206099987007Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\B\\features\\B_features_2017-04-20T12-58-45.12105256319023Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\B\\features\\B_features_2017-04-20T12-58-45.23402720689751Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\B\\features\\B_features_2017-04-20T12-58-45.34804791212059Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\NIR\\features\\NIR_features_2017-04-20T12-58-45.50704926252342Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\NIR\\features\\NIR_features_2017-04-20T12-58-45.59805661439873Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\NIR\\features\\NIR_features_2017-04-20T12-58-45.68302899599053Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\NIR\\features\\NIR_features_2017-04-20T12-58-45.77206492423989Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\NDVI\\features\\NDVI_features_2017-04-20T12-58-45.92603713273979Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\NDVI\\features\\NDVI_features_2017-04-20T12-58-46.01104974746681Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\NDVI\\features\\NDVI_features_2017-04-20T12-58-46.0970279574392Z.csv",
    "C:\\Program Files\\Harris\\ENVI54\\IDL86\\NDVI\\features\\NDVI_features_2017-04-20T12-58-46.18002891540505Z.csv"
]

# Replace the following path with the path stored in the ground_truth variable in the first part of the tutorial.
scene_properties_csv = r"D:\Programming\code\ROIseries\data\sentinel_2a\table\scene_properties.csv"

# Reformat the features and the ground truth into one CSV of ROWS X COLUMS = SAMPLES X FEATURES.
# The csv variable stores the path to the resulting table.
csv = RS_test.ROIseries_feature_sommelier.read_features_and_groundtruth(features_csv,scene_properties_csv)

# Instantiate the feature_sommelier and do a 10 fold cross validation
class_column = "cloudy"
strata_column = "id"
positive_classname = True
RS_cloudy = RS_test.ROIseries_feature_sommelier(csv,class_column, strata_column, positive_classname)
RS_cloudy.folds=10
RS_cloudy.CV()

# Produce some plots from the results of the 10 fold cross validation
RS_cloudy.plot_pr()
RS_cloudy.plot_roc()
RS_cloudy.plot_feature_importance()
RS_cloudy.plot_performance()
RS_cloudy.plot_performance(get_data=True)