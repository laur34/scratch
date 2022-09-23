import pandas as pd
import plotly
import numpy as np
import plotly.graph_objs as go

#plotly.offline.init_notebook_mode()

df = pd.read_csv('ISO_3166-2_country-code_vs_BOLD_and_LH_countriesMaster.csv', sep='\t')

data = [dict(type='choropleth',
			locations = df['3let_LH'].astype(str),
			z=df['NrSpeciesBOLD'].astype(int),
			locationmode='ISO-3',
			colorscale='Greens')]
			
#Append next db data to the data
data.append(data[0].copy())

data[1]['z'] = df['NrSpeciesBOLDGBIF'].astype(int)

#And third data now, too
#data.append(data[0].copy())
#data[2]['z'] = df['NrSpeciesBOLDGBIF'].astype(int)

#Now, let's build our slider
databases = ['BOLD', 'GBIFspeciesInBOLD']
steps = []

for i in range(len(data)):
	step = dict(method='restyle', args=['visible', [False] * len(data)], label='Database {}'.format(databases[i]))
	step['args'][1][i] = True
	steps.append(step)

slider = [dict(active=0, pad={"t": 10, "l": 1200, "r": 1200}, steps=steps, borderwidth=10)]

#Plot
layout = dict(
    title="Species counts in databases",
    font=dict(size=20),
    #margin=dict(l=40, r=40, t=60, b=40),
    #annotations=[dict(x=1, y=1)],
    geo=dict(scope='world', projection={'type': 'robinson'}),
    sliders=slider
    )

fig = dict(data=data, layout=layout)


#fig.show()
plotly.offline.iplot(fig)

