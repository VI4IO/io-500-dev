#!/usr/bin/Rscript

lines = "
A,,5535.02,151.52,36.53,969.45,894.76,15.55,39.09,50.71,49.38,48.89,11.40,,38.73,18.92,43.20,57.63
B,,1611.37,54.20,29.73,333.03,220.62,1.44,81.38,12.66,120.81,14.96,13.67,,127.32,11.30,61.62,38.00
C,100,957.20,21.68,44.16,126.22,180.44,1.44,6.71,20.12,166.33,10.74,19.07,,172.78,8.52,324.87,34.09
D,100,1554.20,22.76,68.29,158.19,163.62,1.53,6.79,18.15,153.05,7.74,17.80,37.58,156.07,8.80,912.86,41.45
E,126,185.32,4.61,40.20,30.73,18.06,0.30,2.71,20.68,161.63,20.39,18.30,,148.62,19.39,47.23,20.69
"
con = textConnection(lines)
data = read.csv(con, header=F)
close(con)
colnames(data) = c("name", "nodes", "score", "bw", "ops",
  "ior_easy_w", "ior_easy_r", "ior_hard_w", "ior_hard_r",
  "md_easy_w", "md_easy_s", "md_easy_d",
  "md_hard_w", "md_hard_r", "md_hard_s", "md_hard_d",
  "find", "totkiops")
data = data[! is.na(data$name), ]

data$totkiops = ( data$ior_easy_w * data$ior_easy_r *
    data$ior_hard_r*1024*1024*1024/47008/1000 * data$ior_hard_w*1024*1024*1024/47008/1000 *
    data$md_easy_w * data$md_easy_s * data$md_easy_d *
    data$md_hard_w *  data$md_hard_s * data$md_hard_d *
    data$find ) ^ (1/11)

vals = ( data$ior_easy_w * data$ior_easy_r *
  data$ior_hard_r*1024*1024*1024/47008/1000 * data$ior_hard_w*1024*1024*1024/47008/1000 *
  data$md_easy_w * data$md_easy_s * data$md_easy_d *
  data$md_hard_w * data$md_hard_r * data$md_hard_s * data$md_hard_d *
  data$find ) ^ (1/12)

data$totkiops = ifelse(is.na(data$totkiops), vals, data$totkiops)

cat(sprintf("%.2f\n", data$totkiops))
