import plotly.graph_objects as go
import pandas as pd

df = pd.read_csv('NumSpecies_by_3lCC.tsv', sep='\t')

fig = go.Figure(data=go.Choropleth(
    locations = df['3let'],
    z = df['SpeciesCount'],
    text = df['Countrylet'],
    colorscale = 'Purples',
    autocolorscale=False,
    reversescale=True,
    marker_line_color='darkgray',
    marker_line_width=0.5,
    colorbar_title = 'Number of species in GBIF',
))

fig.update_layout(
    title_text='Species Counts in GBIF',
    geo=dict(
        showframe=False,
        showcoastlines=False,
        projection_type='equirectangular'
    ),
    annotations = [dict(
        x=0.55,
        y=0.1,
        xref='paper',
        yref='paper',
        text='Source: <a href="https://www.gbif.org/">\
            Global Biodiversity Information Facility</a>',
        showarrow = False
    )]
)

fig.show()

#Make also one for BOLD  countries.

#And be able to scroll between them, like this one:
#https://www.geeksforgeeks.org/how-to-make-a-choropleth-map-with-a-slider-using-plotly-in-python/

#Another idea:
#Filter the map, so that only e.g. big 5 insect taxa are included, and see how it changes.


