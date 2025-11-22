
"""
Project 3: Python, Pandas, Matplotlib and Seaborn
"""

import pandas as pd
import seaborn as sb
import matplotlib.pyplot as plt
import numpy as np

"""
For this project, I wanted to examine the data of the Nobel Prize laureates in history,
in particular the amount of Nobel Prize laureates in each country in proportion to its population.
I expect that developed western nations, presumably nations in Europe and in North America,
will perform the best in terms of Nobel laureates per capita.
Beyond that, I would like to explore the differences between the Nobel Prize categories
in terms of the countries that have had more Nobel laureates in each of them.

I sourced my data from Kaggle here:
https://kaggle.com/datasets/nobelfoundation/nobel-laureates
"""

laureates = pd.read_csv("data/archive.csv")

# Cleaning the dataframe and using only the relevant or noteworthy columns, including changing a value for consistency:

laureates_short = laureates[["Year", "Category", "Prize", "Motivation", "Laureate ID", "Full Name",
                            "Sex", "Organization Name", "Birth Country", "Organization Country"]\
                            ].sort_values(["Year", "Category"])
laureates_short.replace({"United States of America": "United States"}, inplace=True)

# Displaying general information from the dataframe:

print(laureates_short)
laureates_short.info()
laureates_short.describe(include="object")

# Since the columns related to countries are partially null,
# I'll examine prizes awarded which don't have data for either:

print(laureates_short[laureates_short["Birth Country"].isna() & laureates_short["Organization Country"].isna()])

"""
The columns are apparently both null only in cases of Nobel Peace Prizes
given to organizations related to multiple countries or to no country.
For the purpose of this project about the nationalities of Nobel laureates,
it is reasonable to neglect these outliers in the data.
For simplicity, for the rest of the project I will only use the Birth Country column,
which has fewer null values, and I will address the problems with that approach later.

Now moving on to data about the population of each country in the world, also taken from Kaggle:
https://kaggle.com/datasets/iamsouravbanerjee/world-population-dataset
"""

populations = pd.read_csv("data/world_population.csv")

# I will only use data from the year 2000 for consistency,
# since it should suffice for the purpose of comparing the relative population sizes:

pop_2000 = populations[["Rank", "Country/Territory", "Continent", "2000 Population",
                        "World Population Percentage"]].sort_values("Rank")

# Displaying general information from the dataframe:

pop_2000.head(10)
pop_2000.info()

# First I will examine the countries which have had the most Nobel laureates
# in general throughout the years,with no regard to their population sizes:

top_10 = laureates_short[laureates_short["Birth Country"].isin(
    laureates_short.value_counts("Birth Country").index[:10])].groupby("Birth Country")
for country in list(top_10.groups):
    sb.lineplot(laureates_short[laureates_short["Birth Country"] == country]\
        .value_counts("Year").sort_index().cumsum(), errorbar=None)

plt.legend(list(top_10.groups))
plt.show()

# To give perspective, I will display the top 5 most populous countries:

plt.pie(pop_2000["2000 Population"][:5], labels=pop_2000["Country/Territory"][:5],
        autopct=lambda x: f'{int(pop_2000["2000 Population"][:5].sum() * x/100):,}', pctdistance=0.7)
plt.show()

# And some statistical data regarding population sizes:

pop_2000["2000 Population"].describe()

"""
The standard deviation of countries' populations is very high compared to the mean,
with the few most and least populous countries having populations
orders of magnitude different to most other countries.
Unrelated to countries, it is known that every country has roughly 50% of the population of each sex.
However, females are extremely underrepresented as Nobel laureates,
though their representation has improved in recent years, as we can see in this chart:
"""

sb.stripplot(data=laureates_short, x="Sex", y="Year",jitter=0.3)
plt.show()

"""
I will now join the two dataframes using only the countries that appear in both dataframes with the same spelling.
That is why I changed the name of the United States in one of them.
This will cause some of the countries to be omitted in the resulting dataframe -
I will address the drawbacks and limitations of this method later.
"""

nobel_countries = pd.merge(laureates_short, pop_2000, left_on="Birth Country", right_on="Country/Territory")
year_as_index = nobel_countries.set_index("Year")

# We can examine the total amount of Nobel Prize laureates in each country among the countries the dataframe includes:

year_as_index.value_counts("Birth Country")

# Some statistical details regarding the amount of Nobel laureates in each country:

year_as_index.value_counts("Birth Country").describe()

# We can see that some countries, especially the United States, skew the results a lot,
# and many countries have only 1 Nobel laureate.
# I'll now calculate each country's amount of Nobel laureates in relation to its population size:

year_as_index["Relative Population"] = pop_2000["2000 Population"].sum() / year_as_index["2000 Population"]
adjusted = (year_as_index.groupby("Birth Country").sum("Relative Population")["Relative Population"].
            sort_values(ascending=False))

# Though the units I used are meaningless,
# here is a chart of the relative per capita amounts of countries' Nobel laureates:

plt.figure(figsize=(12,4.8))
plt.xticks(rotation=90)
sb.barplot(adjusted)
plt.show()

"""
Some small nations such as Saint Lucia, Luxembourg and Iceland are significantly overrepresented
in the amount of Nobel Prize laureates per capita despite only having 1 or 2 laureates each.
The rest of the top performers are western nations, mostly less populous European countries. One problem
with the approach I took is that it neglected several countries which have changed names in the past century,
such as Mandatory Palestine (Today Israel) and countries that were part of the former Russian Empire.
I'll display more statistics about the relative per capita values of all countries, with the units I calculated:
"""

adjusted.describe()

"""
We now see that while the standard deviation between the countries' total number of Nobel laureates
was significantly larger than the mean,
the standard deviation in the per capita rates of Nobel laureates is somewhat closer to the mean, yet still larger.
It is natural that larger countries would produce more Nobel laureates,
and normalizing for the per capita rates did bring the countries with the most laureates closer to the mean,
while highlighting smaller countries. Still, many countries performed very poorly per capita and few excelled.
Now I want to examine each category of Nobel Prizes separately:
"""

nobel_categories = list(laureates_short["Category"].drop_duplicates())
nobel_by_category = nobel_countries.groupby(["Category", "Birth Country"])["Year"].count().unstack(fill_value=0).stack()

# I'll make a chart to help visualize the distinct categories the different countries
# have had more or less Nobel laureates in:

plt.figure(figsize=(12,4.8))
for i in range(6):
    plt.scatter(list(nobel_countries["Birth Country"].drop_duplicates().sort_values()), nobel_by_category\
        [nobel_categories[i]], color=["r","g","b","c","m","y"][i], marker='x')
    plt.legend(nobel_categories)
    plt.xticks(rotation=90)
plt.show()

"""
It seems that the countries with fewer total Nobel laureates have a high number of Nobel laureates
in peace, economics and literature, while among countries with a medium or higher amount of Nobel laureates,
there is a greater number of laureates in physics, medicine and chemistry.
This can be explained by checking the total amount of Nobel laureates registered in the database in each category:
"""

nobel_countries.groupby("Category")["Year"].count().sort_values(ascending=False)

"""
This discrepancy is due to how many Nobel Prizes are awarded collaboratively to up to 3 people in any given year.
We can note that due to the way I organized the data,
several Nobel Peace Prizes awarded to multiple people or to organizations from multiple countries got omitted.
The dataframe included prizes from 1901 to 2016 - 116 years in total,
and the partial data in the dataframe I use includes most but not all of the Nobel Prizes
in literature, peace and economics, as well as many instances of Nobel Prizes in medicine, physics and chemistry
awarded to multiple laureates, which got counted multiple times.
I'll make a chart to study the categories with a lot of collaborative prizes awarded:
"""

plt.figure(figsize=(15,4))
ax = plt.subplot(1,3,1)
plt.title("Physics")
sb.histplot(data=year_as_index[year_as_index["Category"]=="Physics"], x="Year", binwidth=3, color="m")
plt.subplot(1,3,2,sharey=ax)
plt.title("Chemistry")
sb.histplot(data=year_as_index[year_as_index["Category"]=="Chemistry"], x="Year", binwidth=3, color="r")
plt.subplot(1,3,3,sharey=ax)
plt.title("Medicine")
sb.histplot(data=year_as_index[year_as_index["Category"]=="Medicine"], x="Year", binwidth=3, color="b")
plt.show()

"""
I seems that over the years, more collaborative Nobel Prizes in these categories have been awarded.
Altogether, it is possible that a significant factor in the way some countries were overrepresented
in terms of Nobel laureates per capita is that most of them have produced a great number of Nobel laureates
in scientific categories, and the prizes were awarded to several people in these countries,
which skewed the results in their favor.

In conclusion, my hypothesis that western nations rank at the top in terms of Nobel Prize laureates per capita
turned out to be correct. In particular, the less populous nations performed even better in this statistic:
They still have a supportive environment that promotes the success of Nobel laureates,
and their smaller population amplifies their performance in relation to the other countries.
The top performer - Saint Lucia - is also technically part of North America. Sweden, the country Alfred Nobel is from,
turned out to be the best per capita performer with a population above 1 million.
Some results have surprised me: I didn't expect to see South American countries perform so poorly in this statistic,
with Brazil being the worst per capita performer out of all 55 countries which had data of Nobel laureates.
I've also learned that the statistics I've measured are skewed in favor of Nobel laureates in scientific categories,
while several Nobel Peace Prizes were excluded from the measurements in this project.
"""
