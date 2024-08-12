import pandas as pd
from matplotlib import pyplot as plt
import numpy as np

csv_filename="./results/summary/gfx1102_pytorch_comparison.csv"

data = pd.read_csv(csv_filename)

data.head()
df = pd.DataFrame(data)
df.index=["pt_231", "pt_241rc1", "pt_241rc1_tuned"]

# create figure
df.plot(kind="barh",
        ylabel='Tested Pytorch Version',
        xlabel='Execution Time milliseconds. Lower value is better',
        title='AMD 7700S/gfx1102 Pytorch dot product benchmark on tuned and non-tuned aotriton',
        edgecolor='white',
        linewidth=5)

# show figures
plt.show()
