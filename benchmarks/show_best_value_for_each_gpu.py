import pandas as pd
from matplotlib import pyplot as plt
import numpy as np

csv_filename="./results/summary/gpus_best_value.csv"

data = pd.read_csv(csv_filename)

data.head()
df = pd.DataFrame(data)

# create figure
df.plot(kind="bar",
		xlabel='Tested Graphic Card',
		ylabel='Execution Time milliseconds. Lower value is better',
		title='Dot product benchmark with tuned and non-tuned pytorch241rc1/aotriton',
		edgecolor='white',
		linewidth=5)

# show figures
plt.show()
