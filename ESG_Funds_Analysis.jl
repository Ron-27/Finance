### A Pluto.jl notebook ###
# v0.19.38

using Markdown
using InteractiveUtils

# ╔═╡ 4e56cadc-cd0a-11ee-012a-2fc721cec33f
using SparseArrays, PlutoPlotly, LaTeXStrings, SpecialFunctions,  PlutoUI, DifferentialEquations, DataFrames, CSV, LinearAlgebra, Statistics, Random, MessyTimeSeries, StateSpaceModels, MAT, CategoricalArrays, DataFrames, StableRNGs, JLD2, XLSX, Dates, Statistics, SkipNan, JuMP, Ipopt 

# ╔═╡ 9747955b-9aae-49f9-867b-417f8d854c74
html" <h1><center>Analysis of ESG Funds</center></h1>"

# ╔═╡ 65264515-eb94-4e01-8d55-9ae8c218c735
md" In this notebook, I analyze the returns of several Environmental, Social, and Governance (ESG) funds. I focus on data spanning two distinct periods: before the COVID-19 pandemic (2014-2019) and after (2019-2023). This approach aims to gain insights into the performance of these funds during the crisis. $br

For the analysis, I conduct style and industry analyses using minimum variance optimization. This method reveals the exposure of the different funds to various industry sectors and market indices."

# ╔═╡ 8ad5e30c-a496-4917-83bd-5a184abae2ac
md" I use 'Plotly' package to create all the plots and make them interactive. "

# ╔═╡ 4af67516-b877-42f1-93ab-8a885d86d41b
md" # Importing Data"

# ╔═╡ 8dc7f570-d344-4bb5-a90b-fc0e92a42bdb
md" The data is in Excel file, containng monthly returns of 30 ESG funds, 3-month TBills, and several indices. here I just convert it to Data Frames that are easier to do statistics with"

# ╔═╡ 0c5d6679-f09f-44ea-ad70-a8bfc59e909c
md" ## Importing Excel file"

# ╔═╡ 77645cc1-6b40-4550-a7fc-c7f90e2bda28
begin
file_path = "ESG Fund and Benchmark Data (HW1).xlsx"
xf = XLSX.readxlsx(file_path)
#Next line shows the names of the worksheets:
XLSX.sheetnames(xf)
end

# ╔═╡ 5dfd12e1-f284-4e3b-ae05-3b25d9a5e9d7
md" ## Converting to DataFrames"

# ╔═╡ c12e68b7-2f66-496e-96e8-1d15823721e3
md" ### T-Bills (*df_TBill*)"

# ╔═╡ 1b8d063a-fbe1-4ceb-93b6-d500857a2cad
df_TBill = DataFrame(XLSX.readtable(file_path, "T-Bill Rets", infer_eltypes=true));

# ╔═╡ a014af65-1b5b-4551-9e05-5d46e2277b43
md" ### ESG Funds 10 years (*df_Fund10*)"

# ╔═╡ a7f1e727-5068-4109-9f94-2f80c8571e83
begin
#Skipping the fist two lines due to headers
df_Fund10 = DataFrame(XLSX.readtable(file_path, "Fund Rets - Last 10 years", infer_eltypes=true, first_row=3))
	
#Removing spaces from columns names:
rename!(df_Fund10, names(df_Fund10) .=> replace.(string.(names(df_Fund10)), " " => ""))
#Changing column name:
rename!(df_Fund10, :Ticker => :Date)
end

# ╔═╡ 5c6a2a41-7ba6-4d2f-9b06-052eef3c9dfd
md" ### ESG Funds all-data (*df_Fundall*)"

# ╔═╡ fcb83aa4-8b67-49d1-a242-8e273432630b
begin
#Skipping the fist two lines due to headers
df_Fundall = DataFrame(XLSX.readtable(file_path, "Fund Rets - All Available Data", infer_eltypes=true, first_row=3))
	
#Removing spaces from columns names:
rename!(df_Fundall, names(df_Fundall) .=> replace.(string.(names(df_Fundall)), " " => ""))
#Changing column name:
rename!(df_Fundall, :Ticker => :Date)
end;

# ╔═╡ 97e77ac8-597b-4f69-8e89-c11cecb57ee1
md" ### Benchmark Indices (*df_bmark*) "

# ╔═╡ efe5d7d2-050a-4e40-95ba-6874bdad9292
begin
#Skipping the fist two lines due to headers
df_bmark = DataFrame(XLSX.readtable(file_path, "bmark", infer_eltypes=true, first_row=3))
	
#Removing spaces from columns names:
rename!(df_bmark, names(df_bmark) .=> replace.(string.(names(df_bmark)), " Index" => ""))
#Changing column name:
#rename!(df_Fundall, :Ticker => :Date)
end

# ╔═╡ 4396b45f-2946-4d55-b1de-798534ef3847
md" ### Style Indices (*df_style*)"

# ╔═╡ 9d62d9c2-7516-4433-8fdc-59692b061bf8
begin
#Skipping the fist two lines due to headers
df_styles = DataFrame(XLSX.readtable(file_path, "styles", "D:H", infer_eltypes=true,  first_row=2))
	
dates_sty = DataFrame(XLSX.readtable(file_path, "styles", "A", infer_eltypes=true,  first_row=2))
df_style = hcat(dates_sty,df_styles)
rename!(df_style, [:Date, :Russ1000_Value, :Russ1000_Growth, :Russ_Midcap, :Russ2000, :Momentum])

	
#Removing spaces from columns names:
#rename!(df_styles, names(df_styles) .=> replace.(string.(names(df_styles)), " " => ""))
#Changing column name:
#rename!(df_Fundall, :Ticker => :Date)
end

# ╔═╡ d14ca3ba-7afe-4c8e-b10f-ab0419229f79
md" ### Industry Indices (*df_ind*)"

# ╔═╡ cd685411-3fe7-47d1-95a1-273729d964fb
begin
#Skipping the fist two lines due to headers
df_industry = DataFrame(XLSX.readtable(file_path, "industry", "D:M", infer_eltypes=true,  first_row=1))
	
dates_ind = DataFrame(XLSX.readtable(file_path, "industry", "A", infer_eltypes=true,  first_row=1))
df_ind = hcat(dates_ind,df_industry)
df_ind.Date = Date.(string.(df_ind.Date), "yyyymm")
df_ind

	
#Removing spaces from columns names:
#rename!(df_styles, names(df_styles) .=> replace.(string.(names(df_styles)), " " => ""))
#Changing column name:
#rename!(df_Fundall, :Ticker => :Date)
end

# ╔═╡ 3268c803-3af8-47d1-a0fa-5b204a18bf87
md" #### Style Crisis (*df_stycrisis*)"

# ╔═╡ 9eb1b308-6ca0-45b8-8134-743137f1d4cb
begin
#Skipping the fist two lines due to headers
df_stycrisis = DataFrame(XLSX.readtable(file_path, "styles_crisis", "D:H", infer_eltypes=true,  first_row=2))
	
dates_stycri = DataFrame(XLSX.readtable(file_path, "styles_crisis", "A", infer_eltypes=true,  first_row=2))
hcat(dates_stycri,df_stycrisis)

	
#Removing spaces from columns names:
#rename!(df_styles, names(df_styles) .=> replace.(string.(names(df_styles)), " " => ""))
#Changing column name:
#rename!(df_Fundall, :Ticker => :Date)
end;

# ╔═╡ fd1d1975-af46-4668-a3d0-32e3dea9cdbf
md" #### Industry Crisis (*df_indcrisis*)"

# ╔═╡ 448ab989-73a1-45b2-9b15-7682ead174dd
begin
#Skipping the fist two lines due to headers
df_indcrisis = DataFrame(XLSX.readtable(file_path, "industry_crisis", "D:M", infer_eltypes=true,  first_row=1))
	
dates_indcri = DataFrame(XLSX.readtable(file_path, "industry_crisis", "A", infer_eltypes=true,  first_row=1))
hcat(dates_indcri,df_indcrisis)

	
#Removing spaces from columns names:
#rename!(df_styles, names(df_styles) .=> replace.(string.(names(df_styles)), " " => ""))
#Changing column name:
#rename!(df_Fundall, :Ticker => :Date)
end;

# ╔═╡ 94c65e02-593d-4fd6-a52b-075cd0922d49
md" # ESG Fund Infromation"

# ╔═╡ b1ad96b6-24eb-4d4c-9aa3-c36bfd4bbf7e
chosen = ["Date", "DSBFX", "SUSA", "PXHIX", "MMDEX", "CCPIX", "CBDIX", "BNUEX", "ATEYX", "APPIX", "ACCSX"]

# ╔═╡ e99338ea-9792-4ff5-bedb-7c590816d06c
md"I randomly selected 10 ESG funds from the data, focusing on them to make the analyses. Here is some information from Morningstar and their prospectus:"

# ╔═╡ fd0eb755-290f-4e99-9bfe-7557f4b7e93b
md" #### ACCSX"

# ╔═╡ f55c6672-791f-4062-95d6-add0cbafa7c3
md"""
**RBC BlueBay Access Capital Community Investment Fund**

Investing primarily in high quality debt securities and other debt instruments supporting community development (low-modereate-income individuals and communities).

**Holdings**: 98% Bond holding (securitized)

**Benchmark**: Bloomberg Barclays U.S. government Bond Index, Bloomberg US Securitized Index

**Screening**: Targeted positive screening

**Morningstar Ratings**: 3-star (silver), 5/5 sustainability, low carbon


"""

# ╔═╡ b47f6864-64ae-48bf-984b-d5307cafe705
md" #### APPIX"

# ╔═╡ c192ee1e-9a12-4119-a054-d52b4164b254
md"""
**Appleseed fund Institutional Share**

Invests primarily in a portfolio of equity securities of companies that are undervalued in the opinion of the Fund's adviser.

**Holdings**: 63% Equity, 31% Other (technology, real-estate, industrials, consumer defensive)

**Benchmark**: ?

**Screening**: From [ Appleseed website](https://www.appleseedfund.com/sustainable-investing/): *The Fund performs both negative and positive ESG screens on its investments, and the research involved provides us with important insights into a company’s culture and management’s ability to take a long-term view of the business. ... We exclude fossil fuel producers from the Appleseed portfolio along with several other industries including but not limited to tobacco, gambling, and weapons*

**Morningstar Ratings**: 2-star (bronze), 3/5 sustainability, n/a carbon


"""

# ╔═╡ ef5ff9e0-812f-492c-9307-c870c54c4418
md" #### ATEYX"

# ╔═╡ ca8893fd-d745-4fe4-bcf1-3745a8451b09
md"""
**AB Sustainable Global Thematic Fund Advisor Class**

Identifies sustainable investment themes that are broadly consistent with achieving the UN Sustainable Development Goals.

**Holdings**: 63% US Equity, 36% non US Equity (technology, healthcare, financial services, consumer cyclical)

**Benchmark**: Morningstar Global Allocation Index

**Screening**: Mostly positive screening, but also some negative. From [ AB prospectus](https://dfinview.com/AllianceBernstein/TADF/018780106/P?site=AB): *The Adviser employs a combination of “top-down” and “bottom-up” investment processes with the goal of identifying, based on
its internal research and analysis, securities of companies worldwide, that fit into sustainable investment themes. First, under the “top-down” approach, the Adviser identifies the sustainable investment themes. In addition to this “top-down” thematic approach, the Adviser then uses a “bottom-up” analysis of individual companies, focusing on prospective earnings growth, valuation, and quality of company management and on evaluating a company’s exposure to environmental, social and corporate governance (“ESG”) factors. ESG factors, which can vary across companies and industries, may include environmental impact, corporate governance, ethical business practices, diversity and employee practices, product safety, supply chain management and community impact. Eligible investments include securities of issuers that the Adviser believes will maximize total return while also contributing
to positive societal impact aligned with one or more SDGs. While the Adviser emphasizes company-specific positive selection criteria over broad-based negative screens in assessing a company’s exposure to ESG factors, the Fund will not invest in companies that derive revenue from direct involvement in adult entertainment, alcohol, coal, controversial weapons, firearms, gambling, genetically modified organisms, military contracting, prisons, or tobacco.*

**Morningstar Ratings**: 4-star (bronze), 5/5 sustainability, low carbon


"""

# ╔═╡ d84099c1-3af4-4e96-9ae7-885954c605e1
md" #### BNUEX "

# ╔═╡ 2281846a-9323-4323-966d-0b92acd5179f
md"""
**UBS International Sustainable Equity Fund Class**

From the [UBS prospectus](https://www.ubs.com/us/en/assetmanagement/funds/products/mutual-fund/_jcr_content/mainpar/toplevelgrid/col1/accordionbox_1691868404/accordionsplit/linklist/link_378760345.0344060625.file/PS9jb250ZW50L2RhbS9hc3NldHMvYXNzZXQtbWFuYWdlbWVudC1yZWltYWdpbmVkL3VzL2RvYy9pbnRlcm5hdGlvbmFsLXN1c3RhaW5hYmxlLWVxdWl0eS5wZGY=/international-sustainable-equity.pdf): *The Fund focuses on the alignment of a traditional investment discipline with the concept of sustainability— the potential for long-term maintenance of environmental, economic and social wellbeing. The fund does not invest in securities with more than 5% of sales in alcohol, tobacco, defense, nuclear, GMO (Genetically Modified Organisms), gambling and pornography.*

**Holdings**: 90% non US Equity (financial services, technology, healthcare, industrials)

**Benchmark**: MSCI ACWI ex USA Index

**Screening**: Some negative screening. According to Morningstar, the fund exhibit moderate exposure to companies with high controversies, and also involves in fossil fuels. 

**Morningstar Ratings**: 3-star (neutral), 3/5 sustainability, n/a carbon


"""

# ╔═╡ b6d7a9ef-fc95-40db-8f6e-bd9f21e42e0c
md" #### CBDIX"

# ╔═╡ 2fee660b-5c5c-4f85-9d1e-1b45790827b9
md"""
**Calvert Bond Fund**

From the [Calvert prospectus](https://www.calvert.com/media/24138.pdf): *The portfolio manager(s) seek to invest in companies that manage environmental, social and governance (“ESG”) risk exposures adequately and that are not exposed to excessive ESG risk through their principal business activities. Companies are analyzed by the investment adviser’s ESG analysts utilizing The [Calvert Principles for Responsible Investment (“Principles”)](https://www.calvert.com/media/34498.pdf), a framework for considering ESG factors (a copy of which is included as an appendix to the Fund’s Prospectus). Each company is evaluated relative to an appropriate peer group based on material ESG factors as determined by the investment adviser. Pursuant to the Principles, the investment adviser seeks to identify companies and other issuers that operate in a manner that is consistent with or promotes environmental sustainability and resource efficiency, equitable societies and respect for human rights, and accountable governance and transparency. The Fund generally invests in issuers that are believed by the investment adviser to operate in accordance with the Principles and may also invest in issuers that the investment adviser believes are likely to operate in accordance with the Principles pending the investment adviser’s engagement activity with such issuer*

**Holdings**: 98% Fixed income (securitized, corporate, government)

**Benchmark**: Bloomberg Barclays US Universal Bond Index

**Screening**: Positive screening according to Calvert principles. 

**Morningstar Ratings**: 4-star (bronze), 4/5 sustainability, n/a carbon


"""

# ╔═╡ e10ee5be-f458-4d41-b3ab-193868566f0e
md" #### CCPIX"

# ╔═╡ 22889383-3b4a-4e57-b356-582a0952ffa3
md"""
**Calvert Mid-Cap Fund Class I**

From the [Calvert prospectus](https://www.calvert.com/media/24138.pdf): *The Fund normally invests at least 80% of its net assets, including borrowings for investment purposes, in common stocks of mid-capitalization companies (the “80% Policy”). The Fund defines mid-cap companies as those whose market capitalization falls within the range of the Russell Midcap® Index at the time of investment. As of December 31, 2023, the market capitalization of the Russell Midcap® Index ranged from $270 million to $73.3 billion with a weighted average market capitalization of $24.5 billion. Market capitalizations of companies within the Russell Midcap® Index are subject to change. Although primarily investing in mid-cap U.S. companies, the Fund may also invest in small-cap companies. The Fund may invest in publicly-traded real estate investment trusts (“REITs”). The Fund may also invest up to 25% of its net assets in foreign securities (including American Depositary Receipts (“ADRs”), which are either sponsored or unsponsored, and Global Depositary Receipts (“GDRs”)). The Fund may also lend its securities.*

**Holdings**: 98% US Equity (Industrials, technology, healthcare, consumer cyclical)

**Benchmark**: S&P 500 TR

**Screening**: According to Morningstar, the fund aims to avoid companies in violations with international norms, such as the UN Gloval Compact or the Universal Declaration of Human Rights. No exposure to high or severe controversies. 

**Morningstar Ratings**: 2-star (bronze), 4/5 sustainability, low carbon


"""

# ╔═╡ c12c5796-24e9-4658-8dd4-fded7a873e56
md" #### MMDEX"

# ╔═╡ a3223983-61b4-435d-b57f-94f9bf359890
md"""
**Praxis Growth Index fund Class I**

From the [prospectus](https://prospectus-express.broadridge.com/summary.asp?clientid=mmaprxll&fundid=74006E843): *The Fund seeks to invest in companies aligned with the Stewardship Investing core values: Respecting the dignity and value of all people, Building a world at peace and free from violence, Demonstrating a concern for justice in a global society, Exhibiting responsible management practices, Supporting and involving communities, Practicing environmental stewardshi. In addition, the Adviser uses optimization techniques, including ESG factors, to select securities according to their contribution to the Fund’s overall objective, while seeking to replicate the characteristics of the index, including risk and return characteristics.*

**Holdings**: 98% US Equity (technology, consumer cyclical, communication services, healthcare)

**Benchmark**: S&P 500 Growth Index, Russell 1000 Growth Index

**Screening**: According to Morningstar, the fund aims to avoid companies in violations with international norms, such as the UN Gloval Compact or the Universal Declaration of Human Rights. No exposure to high or severe controversies. 

**Morningstar Ratings**: 4-star (silver), 4/5 sustainability, low carbon


"""

# ╔═╡ 5c8b773b-02e9-4101-837e-b34631fcdada
md" #### PXHIX"

# ╔═╡ 7611ab55-3866-4e06-be4a-107be7f84a6e
md"""
**Impax High Yield Bond Fund Institutional Class**

From the [fund website](https://www.schwab.com/research/mutual-funds/quotes/summary/pxhix): *Under normal market conditions, the fund invests at least 80% of its assets (plus any borrowings for investment purposes) in high-yield, fixed income securities (such as bonds, notes or debentures) that are rated below BBB-by Standard & Poor's Ratings Group or below Baa3 by Moody's Investors Service, similarly rated by another major rating service, or unrated and determined by the fund's investment adviser to be of comparable quality*

**Holdings**: 97% Fixed Income (corporate bonds)

**Benchmark**: Bloomberg US Agg Bond TR USD, ICE BofA US High Yield Bond Index

**Screening**: Positive screening for high yield low quality bond (non or low rated) 

**Morningstar Ratings**: 2-star (neutral), 3/5 sustainability, n/a carbon


"""

# ╔═╡ 2adbaca0-40a2-4508-9ec4-99e2c54ad1aa
md" #### SUSA "

# ╔═╡ 06c4f2dc-6588-41b2-90dc-d4ee82ae55b4
md"""
**iShares MSCI USA ESG Select ETF**

From the [prospectus](https://www.ishares.com/us/library/stream-document?stream=reg&product=IUS-SUSA&shareClass=NA&documentId=925822%7E926099%7E926263%7E2158273%7E2110983&iframeUrlOverride=%2Fus%2Fliterature%2Fprospectus%2Fp-ishares-msci-usa-esg-select-etf-4-30.pdf): *The Fund seeks to track the investment results of the MSCI USA Extended ESG Select Index (the “Underlying Index”), which is an optimized index designed to maximize exposure to positive environmental, social and governance (“ESG”) characteristics, while exhibiting risk and return characteristics similar to
the MSCI USA Index*

**Holdings**: 99% Equity (Technology, healthcare, industrials, financial services)

**Benchmark**: MSCI USA Extended ESG Select Index, S&P 500

**Screening**: The index follows positive and negative screening. The negative screening is detailed on the [website](https://www.ishares.com/us/products/index-screen-definitions/susa)

**Morningstar Ratings**: 4-star (bronze), 5/5 sustainability, low carbon


"""

# ╔═╡ f8b2171b-a842-4e98-bf67-ac260b431e5a
md" #### DSBFX "

# ╔═╡ c19c45d5-ce9d-4176-86e8-6caa3d2074ba
md"""
**Domini Impact Bond fund Inverstor Shares**

From the [fund website](https://domini.com/domini-funds/domini-impact-bond-fund/): *The Fund invests in a portfolio of primarily investment-grade fixed-income securities, including U.S. Government agency bonds, corporate debt, and mortgage- and other asset-backed securities. The Fund maintains an effective duration within two years (plus or minus) of the portfolio duration of the securities comprising the Bloomberg U.S. Aggregate Bond Index. It is managed through a two-step process designed to capitalize on the strengths of Domini Impact Investments and Wellington Management.
Guided by our Impact Investment Standards, Domini sets environmental and social guidelines and objectives for each asset class and creates an approved list of securities based on our in-depth environmental and social research and analysis. Wellington constructs and manages a portfolio of Domini-approved securities using proprietary analytical tools*

**Holdings**: 91% Fixed income (government, securitized, corporate)

**Benchmark**: Bloomberg Barclays US Universal Bond Index, Bloomberg US agg Bond TR USD

**Screening**: Positive according to Domini environmental and social research and analysis

**Morningstar Ratings**: 3-star (neutral), 5/5 sustainability, n/a carbon


"""

# ╔═╡ 1e1e48c7-b3c5-4661-9dec-e820846ce12b
md" # Performance Analytics"

# ╔═╡ 26bd47f0-05a9-448d-8270-32c3b5463560
md" #### Functions"

# ╔═╡ a5f5bc09-2ab8-4f35-a0f0-2f99dfa38701
#Function to convert "NaN" strings to NaN values
convert_NaN(x) = x == "NaN" ? NaN : x

# ╔═╡ d4901f31-4958-4726-b9f8-617dc3c5e1ce
#Function to convert "NaN" strings to NaN values in a DataFrame
function NaNstr_to_NaN(df)
	df_converted = DataFrame([[convert_NaN(x) for x in df[!, col]] for col in names(df)], names(df))
	return df_converted
end

# ╔═╡ 279ceff9-d1fc-49ee-bfe9-6b01faa6e8d8
function filter_year(df, year_0, year_t)
	return df[(@. year_0 <= Dates.year(df.Date) <= year_t) , :]
end

# ╔═╡ 2ecd61dc-4a0b-4149-809c-6192e5e3b946
function annualized_return(avg_monthly_return)
    return ((1 + avg_monthly_return)^12) - 1
end

# ╔═╡ 03a5025f-99d0-4fad-b480-a0e51d40583c
function TBill_Return(df)
	avg = mean(df[:,2] .* 0.01)
	overall = prod(1 .+ skipnan(df[:,2] .* 0.01)) - 1
	return avg, overall
end

# ╔═╡ 4aae45e1-2199-4f39-9c71-349516419767
function Metric_calc(df, RFR)
	df_metrics = DataFrame(Metric = ["Average_Monthly_Return", "Annualized_Return", "Standard_Deviation", "Overall_Return", "Sharpe_Ratio"])
	for col in names(df)[2:end]
    	avg_monthly_return = mean( skipnan(df[!, col]) )
    	ann_return = annualized_return(avg_monthly_return)
    	std_dev = std( skipnan(df[!, col]) )
		overall_return = prod(1 .+ skipnan(df[!, col])) - 1
		sharpe = (avg_monthly_return - RFR) / std_dev
    
    	# Adding a new column to metrics_df for each stock
    	df_metrics[!, Symbol(col)] = [avg_monthly_return, ann_return, std_dev,
									overall_return, sharpe]
	end
	return df_metrics
end

# ╔═╡ 915763b8-98c4-4b11-bf55-8298d9b46865
md" ## TBill Returns"

# ╔═╡ a991e832-106a-416a-8c81-a2e06f03c3b2
TBill_avg, TBill_all = TBill_Return(df_TBill)

# ╔═╡ 833410b3-5fba-41ef-a890-4870f3b6fae8
md" Let's examine the returns of T-Bills and the S&P 500. This comparison will provide insights into the 'risk-free' rates of T-Bills and the market returns represented by the S&P 500. $br
The time scroller at the bottom can help zooming in on specific periods.
"

# ╔═╡ 7c9402b5-53c8-4d1a-84b4-2eda256f774e
begin
trace1 = scatter(x=df_bmark.Date, y=filter_year(df_TBill,2002, 2023)[:, "T-Bill Return"].*0.01, mode="lines", name="TBill", yaxis="y")

# Create the second trace for S&P 500 Returns
trace2 = scatter(x=df_bmark.Date, y=df_bmark.SPXT, mode="lines", name="S&P 500", yaxis="y2")

# Define the layout with dual y-axis
layout = Layout(title="Monthly Returns",
                xaxis=attr(tickformat="%d %b<br>%Y", rangeslider_visible=true),
                yaxis=attr(title="T-Bill", side="left", showgrid=false),
                yaxis2=attr(title="S&P 500", side="right", overlaying="y", showgrid=false),
                )

# Create the figure with both traces and the layout
fig_TbillZ = plot([trace1, trace2], layout)

fig_TbillZ
end

# ╔═╡ d2073599-f56c-4020-8ae6-d9ea900c6349
md" ## Funds Return vs. Risk (2014-2023) "

# ╔═╡ e550c3f8-6654-4c65-897f-aeaa1f03b719
md"
Here I calculate the risk (standard deviation, $\sigma$) and historical return of the ESG funds data during 2014-2023:
"

# ╔═╡ dcec7778-a338-4a27-9dff-0dba2c44905a
md" ## Chosen 10 ESG Funds"

# ╔═╡ 9bcf5636-af5a-421c-ba2d-49e77574abf6
md" The chosen funds can be grouped in the following way: "

# ╔═╡ 7108d45f-552e-44ff-a332-cb2956cfab0f
md"$\begin{array}{cccc}
     \hline
\text { Fund } &  \text {  Bonds/Equity } & \text { US/Foreign } & \text{Screening} \\
\hline \hline    
\text { ACCSX }  & \text {Bonds } & \text {US} & \text{Positive}  \\ 
\hline \text { APPIX }  & \text {Mix} & \text {Mix} & \text{Negative + Positive}  \\
\hline \text { ATEYX }  & \text {Equity} & \text {Mix} & \text{Mostly positive}  \\
\hline \text { BNUEX }  & \text {Equity} & \text {Foreign} & \text{Negative}  \\
\hline \text { CBDIX }  & \text {Bond} & \text {US} & \text{Positive}  \\
\hline \text { CCPIX }  & \text {Equity} & \text {US} & \text{Negative}  \\
\hline \text { DSBFX }  & \text {Bonds} & \text {US} & \text{Positive}  \\
\hline \text { MMDEX }  & \text {Equity} & \text {US} & \text{Negative}  \\
\hline \text { PXHIX }  & \text {Bonds} & \text {US} & \text{Positive}  \\
\hline \text { SUSA }  & \text {Equity} & \text {US} & \text{Negative + Positive}  \\
\hline 
\\
\end{array}$"

# ╔═╡ 48d8c33d-9dcd-4804-8fc4-c8d0c891c023
md" The benchmarks we are going to use in analyzing the returns of the funds are: "

# ╔═╡ 36bf19e0-05b5-4a31-9d2a-b8cb97178641
md"""
$\begin{array}{ccc}
\hline \text { Fund } &  \text {  Standard Benchmark } & \text { ESG Benchmark } & \text{Notes} \\
\hline \text { ACCSX }  & \text {S\&P 500 } & \text {A1SGI} & \text{Bonds \& mostly Canada}  \\
\hline \text { APPIX }  & \text {Russell 2000 } & \text {W1SGI } & \text{20\% non-US equity} \\
\hline \text { ATEYX }  & \text {MSCI World } & \text {W1SGI } & \text{40\% non-US equity} \\
\hline \text { BNUEX }  & \text {MSCI World } & \text {W1SGI } & \text{90\% non-US equity}  \\
\hline \text { CBDIX }  & \text {S\&P 500 } & \text {KLD 400 } & \text{Bonds} \\
\hline \text { CCPIX } & \text {S\&P 500} & \text {KLD 400 } & \text{Mid-cap} \\
\hline \text { DSBFX }  & \text {S\&P 500 } & \text {KLD 400 } & \text{Bonds} \\
\hline \text { MMDEX }  & \text {Russell 2000 } & \text {A1SGI} & \text{Growth} \\
\hline \text { PXHIX }  & \text {Russell 2000 } & \text {A1SGI } & \text{High yield bonds} \\
\hline \text { SUSA }  & \text {S\&P 500} & \text {KLD 400 } & \text{Large \& mid-cap} \\
\end{array}$
"""

# ╔═╡ f5ab47e5-c784-40b4-9a78-5ab918f0b8a6
md" ### Benchmark Indices"

# ╔═╡ ff213ef6-336d-4d77-966d-4247f4f914ac
md"""

**SPXT** :
[S&P 500](https://www.spglobal.com/spdji/en/indices/equity/sp-500/#overview) - 500 largest companies listed on the US stock exchanges

**NDDUWI**:
[MSCI World Index](https://www.msci.com/documents/10199/149ed7bc-316e-4b4c-8ea4-43fcb5bd6523) captures large and mid cap representation across 23 Developed Markets

**RU20INTR**: [Russell 2000 Index](https://www.lseg.com/en/ftse-russell/indices/russell-us#t-russell-2000), small cap segment of the US equity market. Includes approximately 2,000 of the smallest securities

**RU30INTR**: [Russell 3000 Index](https://research.ftserussell.com/Analytics/FactSheets/temp/bd508991-6455-42fd-b008-47caca0b373b.pdf), performance of the largest 3,000 U.S. companies representing approximately 96% of the investable U.S. equity market

**TKLD400U**: [MSCI KLD 400 Social Index](https://www.msci.com/documents/10199/904492e6-527e-4d64-9904-c710bf1533c6), weighted index of 400 US securities that provides exposure to companies with outstanding Environmental, Social and Governance (ESG) ratings and excludes companies whose products have negative social or environmental impacts

**A1SGI**: [Dow Jones Sustainability North America Index](https://www.spglobal.com/spdji/en/indices/esg/dow-jones-sustainability-north-america-composite-index/#overview) comprises North American sustainability leaders as identified by S&P Global through the Corporate Sustainability Assessment (CSA). It represents the top 20% of the largest 600 North American companies in the S&P Global BMI based on long-term economic, environmental and social criteria.

**W1SGI**: [Dow Jones Sustainability World Index](https://www.spglobal.com/spdji/en/indices/esg/dow-jones-sustainability-world-index/#overview) comprises global sustainability leaders as identified by S&P Global through the Corporate Sustainability Assessment (CSA). It represents the top 10% of the largest 2,500 companies in the S&P Global BMI based on long-term economic, environmental and social criteria]


"""

# ╔═╡ c97cf677-ceb9-4353-9ceb-770c8053d99a
md" ### Sharpe Ratio, β & Risk"

# ╔═╡ 3c28deaa-16a7-4b4f-a34b-964259c5c08c
md"
Here I calculate the performance of the ESG funds and their benchmarks. I focus on β, the Sharpe Ratio, and historical returns as measures of performance. β indicates the fund’s
sensitivity to market movements, offering insights into the fund’s strategies. Historical returns provide a
straightforward method to evaluate the fund’s financial success. Meanwhile, the Sharpe Ratio serves as an
effective estimate for assessing returns in relation to risk.
"

# ╔═╡ e1d73e95-23ff-428f-8dfc-081393936547
md"
$$\beta_{i} = \frac{Cov(R_{i},R_{m})}{Var(R_{m})}$$
"

# ╔═╡ a45db449-1fbf-479b-bbb6-a14d4edc4708
md" Where $\beta_{i}$ is the β of the fund, $R_{i}$ is the return of the fund, and $R_{m}$ is the return of the market. Here I use the S&P 500 data for the market. "

# ╔═╡ e9e69514-a0cc-462a-a206-92a66828e230
md"
$$Sharpe_{i} = \frac{R_{i} - R_{TBill}}{\sigma_{i}}$$
"

# ╔═╡ f44de9fc-18e1-4b90-86dc-627c997e2fd0
md" Where Sharpe is the Sharpe Ratio for the fund, $\sigma_{i}$ is the standard deviation of the returns of the fund (risk), and $R_{TBill}$ is the risk free rate calculated from the TBill data "

# ╔═╡ d52558e5-30e9-43e3-a55d-63b90d98065a
df_10_perf = select(df_Fund10, chosen);

# ╔═╡ a027c834-1151-4762-80ff-ea9d38928a1b
function beta(r_fund, r_bmark)
covariance = cov(r_fund,r_bmark)
var_bmark = var(r_bmark)
β = covariance / var_bmark
return β
end

# ╔═╡ 60ace95d-1c81-420c-95ec-b7a5437f8f06
function chosen_metric(Ticker::String, bmark::String, ESGbmark::String, df_fund::DataFrame, df_bmark::DataFrame, RFR::Any, year1::Any, year2::Any)
	r_fund = df_fund[:, Ticker]
	r_bmark = df_bmark[:, bmark]
	r_ESGbmark = df_bmark[:, ESGbmark]
	SP500_10 = filter_year(df_bmark, year1,year2).SPXT
	mkt = mean(SP500_10)
	
	β = beta(r_fund, r_bmark)
	β_capm = beta(r_fund, SP500_10)
	exp_capm = RFR + β_capm * (mkt - RFR)
	mean_return = mean(r_fund)
	fund_return = prod(1 .+ r_fund) - 1
	bmark_return = prod(1 .+ r_bmark) - 1
	ESGbmark_return = prod(1 .+ r_ESGbmark) - 1
	fund_risk = std(r_fund)
	bmark_risk = std(r_bmark)
	ESGbmark_risk = std(r_ESGbmark)
	Sharpe = (mean_return - RFR) / fund_risk
	A = [Ticker, β_capm, exp_capm, fund_risk, fund_return, Sharpe, bmark_return, bmark_risk, ESGbmark_return, ESGbmark_risk]
	return A
end

# ╔═╡ 25752a37-039f-43ce-86c1-b465e18a8a00
function df_FundAnalytics(df_chosen_Fund10,df_bmark10, RFR_10, year1, year2)
df_chosen_metrics = DataFrame("Ticker"=> String[], "β" => Float64[], "Expected_CAPM" => Float64[], "Risk" => Float64[], "Return"=> Float64[], "Sharpe_Ratio"=>Float64[], "Return_bmark"=> Float64[], "Risk_bmark"=> Float64[], "Return_ESGbmark"=> Float64[], "Risk_ESGbmark"=> Float64[])

ACCSX = chosen_metric("ACCSX" , "SPXT" , "A1SGITR", df_chosen_Fund10, df_bmark10, RFR_10, year1, year2)
push!(df_chosen_metrics, ACCSX)

APPIX = chosen_metric("APPIX" , "RU20INTR" , "W1SGITRD", df_chosen_Fund10, df_bmark10, RFR_10, year1, year2)
push!(df_chosen_metrics, APPIX)

ATEYX = chosen_metric("ATEYX" , "NDDUWI" , "W1SGITRD", df_chosen_Fund10, df_bmark10, RFR_10, year1, year2)
push!(df_chosen_metrics, ATEYX)

BNUEX = chosen_metric("BNUEX" , "NDDUWI" , "W1SGITRD", df_chosen_Fund10, df_bmark10, RFR_10, year1, year2)
push!(df_chosen_metrics, BNUEX)

CBDIX = chosen_metric("CBDIX" , "SPXT" , "TKLD400U", df_chosen_Fund10, df_bmark10, RFR_10, year1, year2)
push!(df_chosen_metrics, CBDIX)

CCPIX = chosen_metric("CCPIX" , "SPXT" , "TKLD400U", df_chosen_Fund10, df_bmark10, RFR_10, year1, year2)
push!(df_chosen_metrics, CCPIX)

DSBFX = chosen_metric("DSBFX" , "SPXT" , "TKLD400U", df_chosen_Fund10, df_bmark10, RFR_10, year1, year2)
push!(df_chosen_metrics, DSBFX)
	
MMDEX = chosen_metric("MMDEX" , "RU20INTR" , "A1SGITR", df_chosen_Fund10, df_bmark10, RFR_10, year1, year2)
push!(df_chosen_metrics, MMDEX)

PXHIX = chosen_metric("PXHIX" , "RU20INTR" , "A1SGITR", df_chosen_Fund10, df_bmark10, RFR_10, year1, year2)
push!(df_chosen_metrics, PXHIX)

SUSA = chosen_metric("SUSA" , "SPXT" , "TKLD400U", df_chosen_Fund10, df_bmark10, RFR_10, year1, year2)
push!(df_chosen_metrics, SUSA)
	
return df_chosen_metrics	
end

# ╔═╡ baa6b135-fde1-483d-ab20-12bc670c750e
begin
RFR_10 = mean(filter_year(df_TBill, 2014, 2023)[:,2]) * 0.01	
df_chosen_Fund10 = select(df_Fund10, chosen)
df_bmark10 = filter_year(df_bmark, 2014, 2023)
df_chosen_metrics = df_FundAnalytics(df_chosen_Fund10, df_bmark10, RFR_10, 2014, 2023)

RFR_pre = mean(filter_year(df_TBill, 2014, 2019)[:,2]) * 0.01	
df_chosen_Fund10_pre = filter_year(df_chosen_Fund10, 2014, 2019)
df_bmark10_pre = filter_year(df_bmark, 2014, 2019)
df_chosen_metrics_pre = df_FundAnalytics(df_chosen_Fund10_pre, df_bmark10_pre, RFR_pre, 2014, 2019)

RFR_post = mean(filter_year(df_TBill, 2020, 2023)[:,2]) * 0.01	
df_chosen_Fund10_post = filter_year(df_chosen_Fund10, 2020, 2023)
df_bmark10_post = filter_year(df_bmark, 2020, 2023)
df_chosen_metrics_post = df_FundAnalytics(df_chosen_Fund10_post, df_bmark10_post, RFR_post, 2020, 2023)
end

# ╔═╡ 85c930f9-c2de-449d-861b-8d3ba332941e
begin
p_β = plot(bar(
    x=df_chosen_metrics.Ticker, y=df_chosen_metrics.β,
    marker=attr(color="rgb(191,64,191)", line_color="rgb(8,48,107)", line_width=1.5, opacity=0.6)
), Layout(title_text="β", barmode="stack", xaxis_categoryorder="category ascending"))

p_hist = plot(bar(
    x=df_chosen_metrics.Ticker, y=(df_chosen_metrics.Return),
    marker=attr(color="rgb(191,64,191)", line_color="rgb(8,48,107)", line_width=1.5, opacity=0.6)
), Layout(title_text="Historical Return", barmode="stack", xaxis_categoryorder="category ascending"))

p_sharpe = plot(bar(
    x=df_chosen_metrics.Ticker, y=(df_chosen_metrics.Sharpe_Ratio),
    marker=attr(color="rgb(191,64,191)", line_color="rgb(8,48,107)", line_width=1.5, opacity=0.6)
), Layout(title_text="Sharpe Ratio", barmode="stack", xaxis_categoryorder="category ascending"))

p_10perf = [p_β; p_hist; p_sharpe]
relayout!(p_10perf, height=700, width=700, title_text="Performance of Selected ESG Funds (2014-2023)", showlegend=false)
p_10perf
end

# ╔═╡ 79cbd721-2a16-464f-a7d0-a065c97b6721
md" I use the same formulas on the benchmarks to compare their performance to the ESG funds returns. "

# ╔═╡ 2da60c13-458f-48f5-a6ec-de91fc710224
begin
color_R = ["#9B30FF", "#FF6347", "#32CD32"]
legend_names = ["Fund return","Standard benchmark return","ESG benchmark return"]

p_R_all = plot(
    [bar(df_chosen_metrics, x=:Ticker, y=y, name=legend_names[i], marker_color=color_R[i]) for (i, y) in enumerate([:Return, :Return_bmark, :Return_ESGbmark])],
    Layout(title="Returns of ESG Funds vs. Benchmarks (2014-2023)", showlegend=true)
)

p_R_pre = plot(
    [bar(df_chosen_metrics_pre, x=:Ticker, y=y, name=String(y), marker_color=color_R[i], showlegend=false) for (i, y) in enumerate([:Return, :Return_bmark, :Return_ESGbmark])],
    Layout(title="Returns of ESG Funds vs. Benchmarks (2014-2019)")
)
	
p_R_post = plot(
    [bar(df_chosen_metrics_post, x=:Ticker, y=y, name=String(y), marker_color=color_R[i], showlegend=false) for (i, y) in enumerate([:Return, :Return_bmark, :Return_ESGbmark])],
    Layout(title="Returns of ESG Funds vs. Benchmarks (2020-2023)")
)
p_R = [p_R_all ;  p_R_pre ; p_R_post]
relayout!(p_R, height=700, width=720, legend=attr(orientation="h", y=0.75, yanchor="top"))
p_R
end

# ╔═╡ 36c1b787-508b-4f1b-9e1c-6e805dd4e469
begin
colors = ["#1f77b4", "#ff7f0e", "#2ca02c"]
custom_labels = ["Fund σ","Standard benchmark σ","ESG benchmark σ"]
	
p_sig_all = plot(
    [bar(df_chosen_metrics, x=:Ticker, y=y, name=custom_labels[i], marker=attr(color=colors[i])) for (i, y) in enumerate([:Risk, :Risk_bmark, :Risk_ESGbmark])], 
    Layout(title="Risk of ESG Funds vs. Benchmarks (2014-2023)", yaxis=attr(range=[0.0, 0.06]),  showlegend=true)
)

p_sig_pre = plot(
    [bar(df_chosen_metrics_pre, x=:Ticker, y=y, name=String(y), marker=attr(color=colors[i]), showlegend=false) for (i, y) in enumerate([:Risk, :Risk_bmark, :Risk_ESGbmark])], 
    Layout(title="Risk of ESG Funds vs. Benchmarks (2014-2019)", yaxis=attr(range=[0.0, 0.06])
))

p_sig_post = plot(
    [bar(df_chosen_metrics, x=:Ticker, y=y, name=String(y), marker=attr(color=colors[i]), showlegend=false) for (i, y) in enumerate([:Risk, :Risk_bmark, :Risk_ESGbmark])], 
    Layout(title="Risk of ESG Funds vs. Benchmarks (2020-2023)", yaxis=attr(range=[0.0, 0.06])
))

p_sigma = [p_sig_all ;  p_sig_pre ; p_sig_post]
relayout!(p_sigma, height=700, width=720, legend=attr(orientation="h", y=0.75, yanchor="top"))
p_sigma
end

# ╔═╡ 4d6397ac-5869-42ef-9988-c54d71cd3675
md" # Style Analysis"

# ╔═╡ d8a89820-49a0-4ec0-90d3-89b655f3f52d
md" ## Minimum Variance Optimization"

# ╔═╡ fd7b20a0-6921-4eb7-84df-54a55186d911
md" Here, I use Julia's JuMP to identify the weights that minimize the variance of the return time series for each fund, in accordance with the style and industry indices"

# ╔═╡ c1220fee-d686-445b-ac85-c7d7b5413f38
function min_var(funds_df, indexes_df) # Assuming the dataframes funds_df and indexes_df are defined as before
n_indexes = size(indexes_df, 2) - 1
n_funds = size(funds_df, 2) - 1

# DataFrame to store optimized weights for each fund
optimized_weights_df = DataFrame("Ticker" => names(funds_df)[2:end])
for col_name in names(indexes_df)[2:end]
    optimized_weights_df[!, col_name] = zeros(nrow(optimized_weights_df))
end

# Define the model
for fund in 1:n_funds
    model = Model(Ipopt.Optimizer)
    @variable(model, 0 <= weights[i=1:n_indexes] <= 1)
    @constraint(model, sum(weights) == 1)
    fund_returns = funds_df[!, fund + 1] # Skip the Date column
    index_returns = [indexes_df[!, i + 1] for i in 1:n_indexes] # Skip the Date column, list of vectors
    @objective(model, Min, var(fund_returns .- sum(weights[i] * index_returns[i] for i in 1:n_indexes)))
    optimize!(model)
    
    # Extract optimized weights
    optimized_weights = [value(weights[i]) for i in 1:n_indexes]
    optimized_weights_df[fund,2:end] = optimized_weights
end
return optimized_weights_df
end

# ╔═╡ c29942cf-5a59-4b21-9242-db3e7f5e7dd8
md" ## Plotting Functions"

# ╔═╡ 998cb498-22bd-4a9a-aafb-c16b2272679e
function plot_bar(df)
    Ticker = df.Ticker
    colors = ["#D32F2F", "#1976D2", "#388E3C", "#FBC02D", "#8E24AA", "#F57C00", "#C2185B", "#7B1FA2", "#CDDC39", "#0097A7"]

    # Initialize an empty array to hold the traces
    tra = GenericTrace[]

    # Loop through each column to create a trace for it
    for (i, weight) in enumerate(names(df)[2:end])  # Skip the first column
        weight_data = df[!, weight]
        color_index = mod1(i, length(colors))
        push!(tra, bar(x=Ticker, y=weight_data, name=weight, marker_color=colors[color_index]))
    end
    return tra
end

# ╔═╡ dc929ca4-3df4-4c16-912d-3931c709067f
function plot_bar_noleg(df)
    Ticker = df.Ticker
    colors = ["#D32F2F", "#1976D2", "#388E3C", "#FBC02D", "#8E24AA", "#F57C00", "#C2185B", "#7B1FA2", "#CDDC39", "#0097A7"]

    # Initialize an empty array to hold the traces
    tra = GenericTrace[]

    # Loop through each column to create a trace for it, without adding to the legend
    for (i, weight) in enumerate(names(df)[2:end])  # Skip the first column
        weight_data = df[!, weight]
        color_index = mod1(i, length(colors))
        push!(tra, bar(x=Ticker, y=weight_data, name=weight, showlegend=false, marker_color=colors[color_index]))
    end
    return tra
end

# ╔═╡ db857a08-693f-44aa-be6d-5ebf05c6acf3
begin
df_fun = select(filter_year(df_Fund10,2014,2023), chosen)
df_idx = filter_year(df_style,2014,2023)
sol_all = min_var(df_fun, df_idx)

df_fun_pre = select(filter_year(df_Fund10,2014,2019), chosen)
df_idx_pre = filter_year(df_style,2014,2019)
sol_pre = min_var(df_fun_pre, df_idx_pre)

df_fun_post = select(filter_year(df_Fund10,2020,2023), chosen)
df_idx_post = filter_year(df_style,2020,2023)
sol_post = min_var(df_fun_post, df_idx_post)	
end

# ╔═╡ db399be8-c655-40b2-b55c-9f5cee33735a
md" ## Style Analysis (ESG Funds)"

# ╔═╡ 3992c8e2-ea5c-4eda-9e68-9b0932fa9ff1
begin
p_10 = plot(plot_bar(sol_all), Layout(title="Style Analysis (2014-2023)",
				yaxis_title="Weight Value",))

p_pre = plot(plot_bar_noleg(sol_pre), Layout(title="Style Analysis Pre-COVID (2015-2019)",
				yaxis_title="Weight Value"))

p_post = plot(plot_bar_noleg(sol_post), Layout(title="Style Analysis COVID and after (2020-2023)",
				yaxis_title="Weight Value"))

p = [p_10; p_pre; p_post]
relayout!(p, height=700, width=700, bgcolor="rgba(255, 255, 255, 0)", legend=attr(orientation="h", y=0.75, yanchor="top"))
p
	
end

# ╔═╡ 216ce65b-2c60-41b1-a1b8-b0808435cf72
begin
df_bmark_all = filter_year(df_bmark,2014,2023)
sol_bmark_all = min_var(df_bmark_all, df_idx)

df_bmark_pre = filter_year(df_bmark,2014,2019)
sol_bmark_pre = min_var(df_bmark_pre, df_idx_pre)

df_bmark_post = filter_year(df_bmark,2020,2023)
sol_bmark_post = min_var(df_bmark_post, df_idx_post)
end

# ╔═╡ 785400a5-1577-4779-a93e-e5e84b854038
md" ## Style Analysis (Benchmarks)"

# ╔═╡ 10f6c5d8-2dbb-422d-9726-a81f6c06164e
begin
p_10_bmark = plot(plot_bar(sol_bmark_all), Layout(title="Style Analysis (2014-2023)",
				yaxis_title="Weight Value",))

p_pre_bmark = plot(plot_bar_noleg(sol_bmark_pre), Layout(title="Style Analysis Pre-COVID (2015-2019)",
				yaxis_title="Weight Value"))

p_post_bmark = plot(plot_bar_noleg(sol_bmark_post), Layout(title="Style Analysis COVID and after (2020-2023)",
				yaxis_title="Weight Value"))

p_bmark = [p_10_bmark; p_pre_bmark; p_post_bmark]
relayout!(p_bmark, height=700, width=700, bgcolor="rgba(255, 255, 255, 0)", legend=attr(orientation="h", y=0.75, yanchor="top"))
p_bmark
end

# ╔═╡ 9bfd4119-dfb6-494d-b396-295a9a92ddbf
md" # Industry Analysis"

# ╔═╡ 917e0469-28ca-4bae-8d8a-b139a12fe0c0
begin
df_idx_ind = filter_year(df_ind,2014,2023)
sol_all_ind = min_var(df_fun, df_idx_ind)


df_idx_pre_ind = filter_year(df_ind,2014,2019)
sol_pre_ind = min_var(df_fun_pre, df_idx_pre_ind)

df_idx_post_ind = filter_year(df_ind,2020,2023)
sol_post_ind = min_var(df_fun_post, df_idx_post_ind)
end

# ╔═╡ 24eee1af-6cfe-4b63-89e7-5add1b2399a4
md" ## Industry Analysis (ESG Funds)"

# ╔═╡ 775fbcd7-77b4-4b54-8cde-c4a136a33bd4
begin
p_10_ind = plot(plot_bar(sol_all_ind), Layout(title="Industry Analysis (2014-2023)",
				yaxis_title="Weight Value",))

p_10_ind_pre = plot(plot_bar_noleg(sol_pre_ind ), Layout(title="Industry Analysis (2014-2019)",
				yaxis_title="Weight Value",))

p_10_ind_post = plot(plot_bar_noleg(sol_post_ind ), Layout(title="Industry Analysis (2020-2023)",
				yaxis_title="Weight Value",))

p_ind = [p_10_ind; p_10_ind_pre; p_10_ind_post]
relayout!(p_ind, height=700, width=700, bgcolor="rgba(255, 255, 255, 0)", legend=attr(orientation="h", y=0.75, yanchor="top"))
p_ind
end

# ╔═╡ ee1a1abb-2abd-4ee2-a72c-ac3c0d9247c7
begin
sol_all_ind_bmark = min_var(df_bmark_all, df_idx_ind)

sol_pre_ind_bmark = min_var(df_bmark_pre, df_idx_pre_ind)

sol_post_ind_bmark = min_var(df_bmark_post, df_idx_post_ind)
end

# ╔═╡ 2978ac5a-3a59-47fa-ace3-f0910ade0b0e
md" ## Industry Analysis (Benchmarks)"

# ╔═╡ f3a98e92-e257-443f-b809-02c2afcefe42
begin
p_10_ind_bmark = plot(plot_bar(sol_all_ind_bmark), Layout(title="Industry Analysis (2014-2023)",
				yaxis_title="Weight Value",))

p_10_ind_pre_bmark = plot(plot_bar_noleg(sol_pre_ind_bmark ), Layout(title="Industry Analysis (2014-2019)",
				yaxis_title="Weight Value",))

p_10_ind_post_bmark = plot(plot_bar_noleg(sol_post_ind_bmark ), Layout(title="Industry Analysis (2020-2023)",
				yaxis_title="Weight Value",))

p_ind_bmark = [p_10_ind_bmark; p_10_ind_pre_bmark; p_10_ind_post_bmark]
relayout!(p_ind_bmark, height=700, width=700, bgcolor="rgba(255, 255, 255, 0)", legend=attr(orientation="h", y=0.75, yanchor="top"))
p_ind_bmark
end

# ╔═╡ bf1a1ae1-b2f0-4fb2-9b29-09bad0c2110e
md" # Style & Industry Performance"

# ╔═╡ c994e08d-dddb-4e7c-a9a7-b34dbb28f49f
function styind_metric(df::DataFrame, year1::Any, year2::Any)
	RFR = mean(filter_year(df_TBill, year1, year2)[:,2]) * 0.01
	SP500_10 = filter_year(df_bmark, year1,year2).SPXT
	mkt = mean(SP500_10)
	df_calc = filter_year(df, year1, year2)

	df_metrics = DataFrame("Ticker"=> String[], "β" => Float64[], "Risk" => Float64[], "Sharpe_Ratio"=>Float64[], "Return"=> Float64[])

	for col in names(df_calc)[2:end]
		r = df_calc[:, col]
		β = beta(r, SP500_10)
		risk = std(r)
		Sharpe = (mean(r) - RFR) / risk
		r_all = prod(1 .+ r) - 1

		push!(df_metrics, [col, β, risk, Sharpe, r_all])
	end

	return df_metrics
end

# ╔═╡ 09ff7dbf-268e-48c3-bc08-66d5e0bf47d1
begin
df_sty_perf_all = styind_metric(df_style, 2014, 2023)
df_sty_perf_pre = styind_metric(df_style, 2014, 2019)
df_sty_perf_post = styind_metric(df_style, 2020, 2023)

df_ind_perf_all = styind_metric(df_ind, 2014, 2023)
df_ind_perf_pre = styind_metric(df_ind, 2014, 2019)
df_ind_perf_post = styind_metric(df_ind, 2020, 2023)
end;

# ╔═╡ 438a8174-be9c-40dd-9490-b7d2e1999141
function single_bar(df_data, var, title)
	p = plot(bar(
    x=df_data.Ticker, y=df_data[:, var],
    marker=attr(color="rgb(191,64,191)", line_color="rgb(8,48,107)", line_width=1.5, 	opacity=0.6)
	), Layout(title_text=title, barmode="stack", xaxis_categoryorder="category ascending"))
	return p
end

# ╔═╡ 74528d4d-9c5a-47f7-a9ec-d1910074e702
function perf_plot(df_chosen_metrics, df_sty_perf_all, title)

# Add each plot to the figure

p_f_all1 = single_bar(df_chosen_metrics, "β", "β")
p_f_all2 = single_bar(df_chosen_metrics,  "Risk", "Risk (σ)")
p_f_all3 = single_bar(df_chosen_metrics,  "Sharpe_Ratio", "Sharpe Ratio")

	
p_sty1 = single_bar(df_sty_perf_all, "β", "β")
p_sty2 = single_bar(df_sty_perf_all, "Risk", "Risk (σ)")
p_sty3 = single_bar(df_sty_perf_all, "Sharpe_Ratio", "Sharpe Ratio")

# Adjust the layout

fig = [p_f_all1 p_sty1 ; p_f_all2 p_sty2 ;  p_f_all3 p_sty3]
relayout!(fig, height=700, width=700, title_text=title, showlegend=false)
return fig
end

# ╔═╡ 0eb4bd4b-3f09-4afb-915a-c46ab75cabd7
md" ## ESG Funds & Style"

# ╔═╡ 3595b148-2c9e-4581-9a7e-0e9748e4d106
perf_plot(df_chosen_metrics, df_sty_perf_all, "Performance of ESG Funds vs. Style (2014-2023)")

# ╔═╡ a1b1270d-5711-4531-9f33-53ae3ea2cbd6
perf_plot(df_chosen_metrics_pre, df_sty_perf_pre, "Performance of ESG Funds vs. Style (2014-2019)")

# ╔═╡ 9be06855-4722-470d-bfe5-d9491c9bcb51
perf_plot(df_chosen_metrics_post, df_sty_perf_post, "Performance of ESG Funds vs. Style (2020-2023)")

# ╔═╡ b282d5e0-1ed7-479a-9a01-30713b05742b
md" ## ESG Funds & Industry"

# ╔═╡ e24ae473-3441-4580-80af-25fc8dfcf23b
perf_plot(df_chosen_metrics, df_ind_perf_all, "Performance of ESG Funds vs. Industry (2014-2023)")

# ╔═╡ 055cc198-5fd4-444b-b5a9-0bf7bc25baea
perf_plot(df_chosen_metrics_pre, df_ind_perf_pre, "Performance of ESG Funds vs. Industry (2014-2019)")

# ╔═╡ 9bad981f-cdef-4828-a5cf-eb2efc356b35
perf_plot(df_chosen_metrics_post, df_ind_perf_post, "Performance of ESG Funds vs. Industry (2020-2023)")

# ╔═╡ 61ef1273-0511-4c77-be27-8dee734d2e7c
md" # Packages"

# ╔═╡ a0d48ab4-a699-463d-8534-713f041a069e
TableOfContents()

# ╔═╡ ac3e7af7-f6b3-449f-a006-e392848c151e
md" # Extras "

# ╔═╡ 66d42767-7faf-4c67-84fe-8d49913a199b
names(df_ind)[2:end]

# ╔═╡ 1c5cf467-2050-479d-b07d-26bb7765482e
df_Funds10_metric = Metric_calc(df_Fund10, TBill_avg)

# ╔═╡ 4977aea3-982c-4a92-ae48-3bbac1362b94
begin
sc10_overall = GenericTrace[]

	for i in 2:ncol(df_Funds10_metric)
		push!(sc10_overall, scatter(x=[df_Funds10_metric[3, i]], y=[df_Funds10_metric[4, i]], mode="markers", name=names(df_Funds10_metric)[i]))
	end
plot(sc10_overall, Layout(title="ESG Funds Historical Return vs. Risk (2014-2023)", 
				xaxis_title="Risk (σ)",
				yaxis_title="Overall Return",
				showlegend=true))
end

# ╔═╡ dbf45b45-4e4d-4945-ad11-3eeac47da5d3
begin
df_Fundall_fix = NaNstr_to_NaN(df_Fundall)
df_Fundall_metric = Metric_calc(df_Fundall_fix, TBill_avg)
end

# ╔═╡ 45d9cd2d-bd6b-488f-ad99-d67751081bf6
begin
x_all = names(df_Fundall)[2:end]
y_all = Array(df_Fundall_metric[5,2:end])
plot(bar(
    x=x_all, y=y_all,
    marker=attr(color="rgb(191,64,191)", line_color="rgb(8,48,107)", line_width=1.5, opacity=0.6)
), Layout(title_text="Sharpe Ratio (all data)", barmode="stack", xaxis_categoryorder="total descending"))
end

# ╔═╡ c9d7eca9-1a70-4698-b98a-f05689dd8018
begin
scall_overall = GenericTrace[]

	for i in 2:ncol(df_Fundall_metric)
		push!(scall_overall, scatter(x=[df_Fundall_metric[3, i]], y=[df_Fundall_metric[4, i]], mode="markers", name=names(df_Fundall_metric)[i]))
	end
plot(scall_overall, Layout(title="ESG Funds Overall Return All Data", 
				xaxis_title="Risk (σ)",
				yaxis_title="Overall Return",
				showlegend=true))
end

# ╔═╡ b2e2c39c-38ef-42fb-a7ea-feca602ac793
begin
x = names(df_Fund10)[2:end]
y = Array(df_Funds10_metric[5,2:end])
plot(bar(
    x=x, y=y,
    marker=attr(color="rgb(191,64,191)", line_color="rgb(8,48,107)", line_width=1.5, opacity=0.6)
), Layout(title_text="Sharpe Ratio (10 years data)", barmode="stack", xaxis_categoryorder="total descending"))
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
CategoricalArrays = "324d7699-5711-5eae-9e2f-1d82baa6b597"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
DifferentialEquations = "0c46a032-eb83-5123-abaf-570d42b7fbaa"
Ipopt = "b6b21f68-93f8-5de0-b562-5493be1d77c9"
JLD2 = "033835bb-8acc-5ee8-8aae-3f567f8a3819"
JuMP = "4076af6c-e467-56ae-b986-b466b2749572"
LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
MAT = "23992714-dd62-5051-b70f-ba57cb901cac"
MessyTimeSeries = "2a88db5c-15f1-4b3e-a070-d1159e8d76cc"
PlutoPlotly = "8e989ff0-3d88-8e9f-f020-2b208a939ff0"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
SkipNan = "aed68c70-c8b0-4309-8cd1-d392a74f991a"
SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"
StableRNGs = "860ef19b-820b-49d6-a774-d7a799459cd3"
StateSpaceModels = "99342f36-827c-5390-97c9-d7f9ee765c78"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
XLSX = "fdbf4ff8-1666-58a4-91e7-1b58723a45e0"

[compat]
CSV = "~0.10.12"
CategoricalArrays = "~0.10.8"
DataFrames = "~1.6.1"
DifferentialEquations = "~7.12.0"
Ipopt = "~1.6.1"
JLD2 = "~0.4.46"
JuMP = "~1.20.0"
LaTeXStrings = "~1.3.1"
MAT = "~0.10.6"
MessyTimeSeries = "~0.2.6"
PlutoPlotly = "~0.4.4"
PlutoUI = "~0.7.56"
SkipNan = "~0.2.0"
SpecialFunctions = "~2.3.1"
StableRNGs = "~1.0.1"
StateSpaceModels = "~0.6.7"
XLSX = "~0.10.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.1"
manifest_format = "2.0"
project_hash = "bdba472cc801aaaa67266d3e9bdfdd5965c3de9a"

[[deps.ADTypes]]
git-tree-sha1 = "41c37aa88889c171f1300ceac1313c06e891d245"
uuid = "47edcb42-4c32-4615-8424-f2b9edc5f35b"
version = "0.2.6"

[[deps.ASL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6252039f98492252f9e47c312c8ffda0e3b9e78d"
uuid = "ae81ac8f-d209-56e5-92de-9978fef736f9"
version = "0.1.3+0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "c278dfab760520b8bb7e9511b968bf4ba38b7acc"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.2.3"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "cde29ddf7e5726c9fb511f340244ea3481267608"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.7.2"
weakdeps = ["StaticArrays"]

    [deps.Adapt.extensions]
    AdaptStaticArraysExt = "StaticArrays"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "62e51b39331de8911e4a7ff6f5aaf38a5f4cc0ae"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.2.0"

[[deps.ArrayInterface]]
deps = ["Adapt", "LinearAlgebra", "Requires", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "c5aeb516a84459e0318a02507d2261edad97eb75"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "7.7.1"

    [deps.ArrayInterface.extensions]
    ArrayInterfaceBandedMatricesExt = "BandedMatrices"
    ArrayInterfaceBlockBandedMatricesExt = "BlockBandedMatrices"
    ArrayInterfaceCUDAExt = "CUDA"
    ArrayInterfaceGPUArraysCoreExt = "GPUArraysCore"
    ArrayInterfaceStaticArraysCoreExt = "StaticArraysCore"
    ArrayInterfaceTrackerExt = "Tracker"

    [deps.ArrayInterface.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    StaticArraysCore = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.ArrayLayouts]]
deps = ["FillArrays", "LinearAlgebra"]
git-tree-sha1 = "64d582bcb9c93ac741234789eeb4f16812413efb"
uuid = "4c555306-a7a7-4459-81d9-ec55ddd5c99a"
version = "1.6.0"
weakdeps = ["SparseArrays"]

    [deps.ArrayLayouts.extensions]
    ArrayLayoutsSparseArraysExt = "SparseArrays"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.BandedMatrices]]
deps = ["ArrayLayouts", "FillArrays", "LinearAlgebra", "PrecompileTools"]
git-tree-sha1 = "931f3f49902e9b6b527fd7cd02d1cd7b4a84264c"
uuid = "aae01518-5342-5314-be14-df237901396f"
version = "1.5.0"
weakdeps = ["SparseArrays"]

    [deps.BandedMatrices.extensions]
    BandedMatricesSparseArraysExt = "SparseArrays"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BaseDirs]]
git-tree-sha1 = "eee4c0b706ea28cb02e4f2a94dadc6665fc6682a"
uuid = "18cc8868-cbac-4acf-b575-c8ff214dc66f"
version = "1.2.2"

[[deps.BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "f1f03a9fa24271160ed7e73051fba3c1a759b53f"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.4.0"

[[deps.BitTwiddlingConvenienceFunctions]]
deps = ["Static"]
git-tree-sha1 = "0c5f81f47bbbcf4aea7b2959135713459170798b"
uuid = "62783981-4cbd-42fc-bca8-16325de8dc4b"
version = "0.1.5"

[[deps.BoundaryValueDiffEq]]
deps = ["ADTypes", "Adapt", "ArrayInterface", "BandedMatrices", "ConcreteStructs", "DiffEqBase", "FastAlmostBandedMatrices", "ForwardDiff", "LinearAlgebra", "LinearSolve", "NonlinearSolve", "PreallocationTools", "PrecompileTools", "Preferences", "RecursiveArrayTools", "Reexport", "SciMLBase", "Setfield", "SparseArrays", "SparseDiffTools", "Tricks", "TruncatedStacktraces", "UnPack"]
git-tree-sha1 = "dd234c9a030350d5ff4c45761d6cad0cfb358cb9"
uuid = "764a87c0-6b3e-53db-9096-fe964310641d"
version = "5.6.0"

    [deps.BoundaryValueDiffEq.extensions]
    BoundaryValueDiffEqODEInterfaceExt = "ODEInterface"
    BoundaryValueDiffEqOrdinaryDiffEqExt = "OrdinaryDiffEq"

    [deps.BoundaryValueDiffEq.weakdeps]
    ODEInterface = "54ca160b-1b9f-5127-a996-1867f4bc2a2c"
    OrdinaryDiffEq = "1dea7af3-3e70-54e6-95c3-0bf5283fa5ed"

[[deps.BufferedStreams]]
git-tree-sha1 = "4ae47f9a4b1dc19897d3743ff13685925c5202ec"
uuid = "e1450e63-4bb3-523b-b2a4-4ffa8c0fd77d"
version = "1.2.1"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9e2a6b69137e6969bab0152632dcb3bc108c8bdd"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+1"

[[deps.CEnum]]
git-tree-sha1 = "389ad5c84de1ae7cf0e28e381131c98ea87d54fc"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.5.0"

[[deps.CPUSummary]]
deps = ["CpuId", "IfElse", "PrecompileTools", "Static"]
git-tree-sha1 = "601f7e7b3d36f18790e2caf83a882d88e9b71ff1"
uuid = "2a0fbf3d-bb9c-48f3-b0a9-814d99fd7ab9"
version = "0.2.4"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "PrecompileTools", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings", "WorkerUtilities"]
git-tree-sha1 = "679e69c611fff422038e9e21e270c4197d49d918"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.12"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.CategoricalArrays]]
deps = ["DataAPI", "Future", "Missings", "Printf", "Requires", "Statistics", "Unicode"]
git-tree-sha1 = "1568b28f91293458345dabba6a5ea3f183250a61"
uuid = "324d7699-5711-5eae-9e2f-1d82baa6b597"
version = "0.10.8"

    [deps.CategoricalArrays.extensions]
    CategoricalArraysJSONExt = "JSON"
    CategoricalArraysRecipesBaseExt = "RecipesBase"
    CategoricalArraysSentinelArraysExt = "SentinelArrays"
    CategoricalArraysStructTypesExt = "StructTypes"

    [deps.CategoricalArrays.weakdeps]
    JSON = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
    SentinelArrays = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
    StructTypes = "856f2bd8-1eba-4b0a-8007-ebc267875bd4"

[[deps.CloseOpenIntervals]]
deps = ["Static", "StaticArrayInterface"]
git-tree-sha1 = "70232f82ffaab9dc52585e0dd043b5e0c6b714f1"
uuid = "fb6a15b2-703c-40df-9091-08a04967cfa9"
version = "0.1.12"

[[deps.CodecBzip2]]
deps = ["Bzip2_jll", "Libdl", "TranscodingStreams"]
git-tree-sha1 = "9b1ca1aa6ce3f71b3d1840c538a8210a043625eb"
uuid = "523fee87-0ab8-5b00-afb7-3ecf72e48cfd"
version = "0.8.2"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "59939d8a997469ee05c4b4944560a820f9ba0d73"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.4"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "67c1f244b991cad9b0aa4b7540fb758c2488b129"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.24.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "a1f44953f2382ebb937d60dafbe2deea4bd23249"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.10.0"
weakdeps = ["SpecialFunctions"]

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "fc08e5930ee9a4e03f84bfb5211cb54e7769758a"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.10"

[[deps.CommonSolve]]
git-tree-sha1 = "0eee5eb66b1cf62cd6ad1b460238e60e4b09400c"
uuid = "38540f10-b2f7-11e9-35d8-d573e4eb0ff2"
version = "0.2.4"

[[deps.CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "75bd5b6fc5089df449b5d35fa501c846c9b6549b"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.12.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.0+0"

[[deps.ConcreteStructs]]
git-tree-sha1 = "f749037478283d372048690eb3b5f92a79432b34"
uuid = "2569d6c7-a4a2-43d3-a901-331e8e4be471"
version = "0.2.3"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "c53fc348ca4d40d7b371e71fd52251839080cbc9"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.5.4"

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseStaticArraysExt = "StaticArrays"

    [deps.ConstructionBase.weakdeps]
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.CpuId]]
deps = ["Markdown"]
git-tree-sha1 = "fcbb72b032692610bfbdb15018ac16a36cf2e406"
uuid = "adafc99b-e345-5852-983c-f28acb93d879"
version = "0.3.1"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "DataStructures", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrecompileTools", "PrettyTables", "Printf", "REPL", "Random", "Reexport", "SentinelArrays", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "04c738083f29f86e62c8afc341f0967d8717bdb8"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.6.1"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "ac67408d9ddf207de5cfa9a97e114352430f01ed"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.16"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelayDiffEq]]
deps = ["ArrayInterface", "DataStructures", "DiffEqBase", "LinearAlgebra", "Logging", "OrdinaryDiffEq", "Printf", "RecursiveArrayTools", "Reexport", "SciMLBase", "SimpleNonlinearSolve", "SimpleUnPack"]
git-tree-sha1 = "6725c56e3e3d563e37d8fd5e6c5eb66ac19321fd"
uuid = "bcd4f6db-9728-5f36-b5f7-82caef46ccdb"
version = "5.46.0"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.DiffEqBase]]
deps = ["ArrayInterface", "DataStructures", "DocStringExtensions", "EnumX", "EnzymeCore", "FastBroadcast", "ForwardDiff", "FunctionWrappers", "FunctionWrappersWrappers", "LinearAlgebra", "Logging", "Markdown", "MuladdMacro", "Parameters", "PreallocationTools", "PrecompileTools", "Printf", "RecursiveArrayTools", "Reexport", "SciMLBase", "SciMLOperators", "Setfield", "SparseArrays", "Static", "StaticArraysCore", "Statistics", "Tricks", "TruncatedStacktraces"]
git-tree-sha1 = "3089c8295ab6d7c728cd6929121c1b4567457306"
uuid = "2b5f629d-d688-5b77-993f-72d75c75574e"
version = "6.147.0"

    [deps.DiffEqBase.extensions]
    DiffEqBaseChainRulesCoreExt = "ChainRulesCore"
    DiffEqBaseDistributionsExt = "Distributions"
    DiffEqBaseEnzymeExt = ["ChainRulesCore", "Enzyme"]
    DiffEqBaseGeneralizedGeneratedExt = "GeneralizedGenerated"
    DiffEqBaseMPIExt = "MPI"
    DiffEqBaseMeasurementsExt = "Measurements"
    DiffEqBaseMonteCarloMeasurementsExt = "MonteCarloMeasurements"
    DiffEqBaseReverseDiffExt = "ReverseDiff"
    DiffEqBaseTrackerExt = "Tracker"
    DiffEqBaseUnitfulExt = "Unitful"

    [deps.DiffEqBase.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    GeneralizedGenerated = "6b9d7cbe-bcb9-11e9-073f-15a7a543e2eb"
    MPI = "da04e1cc-30fd-572f-bb4f-1f8673147195"
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    MonteCarloMeasurements = "0987c9cc-fe09-11e8-30f0-b96dd679fdca"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.DiffEqCallbacks]]
deps = ["DataStructures", "DiffEqBase", "ForwardDiff", "Functors", "LinearAlgebra", "Markdown", "NLsolve", "Parameters", "RecipesBase", "RecursiveArrayTools", "SciMLBase", "StaticArraysCore"]
git-tree-sha1 = "ee954c8b9d348b7a8a6aec5f28288bf5adecd4ee"
uuid = "459566f4-90b8-5000-8ac3-15dfb0a30def"
version = "2.37.0"
weakdeps = ["OrdinaryDiffEq", "Sundials"]

[[deps.DiffEqNoiseProcess]]
deps = ["DiffEqBase", "Distributions", "GPUArraysCore", "LinearAlgebra", "Markdown", "Optim", "PoissonRandom", "QuadGK", "Random", "Random123", "RandomNumbers", "RecipesBase", "RecursiveArrayTools", "Requires", "ResettableStacks", "SciMLBase", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "3d440ee25f48e5c7b08af71f2997daca45bf6856"
uuid = "77a26b50-5914-5dd7-bc55-306e6241c503"
version = "5.20.1"

    [deps.DiffEqNoiseProcess.extensions]
    DiffEqNoiseProcessReverseDiffExt = "ReverseDiff"

    [deps.DiffEqNoiseProcess.weakdeps]
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"

[[deps.DiffResults]]
deps = ["StaticArraysCore"]
git-tree-sha1 = "782dd5f4561f5d267313f23853baaaa4c52ea621"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.1.0"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "23163d55f885173722d1e4cf0f6110cdbaf7e272"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.15.1"

[[deps.DifferentialEquations]]
deps = ["BoundaryValueDiffEq", "DelayDiffEq", "DiffEqBase", "DiffEqCallbacks", "DiffEqNoiseProcess", "JumpProcesses", "LinearAlgebra", "LinearSolve", "NonlinearSolve", "OrdinaryDiffEq", "Random", "RecursiveArrayTools", "Reexport", "SciMLBase", "SteadyStateDiffEq", "StochasticDiffEq", "Sundials"]
git-tree-sha1 = "8864b6a953eeba7890d23258aca468d90ca73fd6"
uuid = "0c46a032-eb83-5123-abaf-570d42b7fbaa"
version = "7.12.0"

[[deps.Distances]]
deps = ["LinearAlgebra", "Statistics", "StatsAPI"]
git-tree-sha1 = "66c4c81f259586e8f002eacebc177e1fb06363b0"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.11"

    [deps.Distances.extensions]
    DistancesChainRulesCoreExt = "ChainRulesCore"
    DistancesSparseArraysExt = "SparseArrays"

    [deps.Distances.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns"]
git-tree-sha1 = "7c302d7a5fec5214eb8a5a4c466dcf7a51fcf169"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.107"

    [deps.Distributions.extensions]
    DistributionsChainRulesCoreExt = "ChainRulesCore"
    DistributionsDensityInterfaceExt = "DensityInterface"
    DistributionsTestExt = "Test"

    [deps.Distributions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DensityInterface = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "5837a837389fccf076445fce071c8ddaea35a566"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.8"

[[deps.EnumX]]
git-tree-sha1 = "bdb1942cd4c45e3c678fd11569d5cccd80976237"
uuid = "4e289a0a-7415-4d19-859d-a7e5c4648b56"
version = "1.0.4"

[[deps.EnzymeCore]]
git-tree-sha1 = "59c44d8fbc651c0395d8a6eda64b05ce316f58b4"
uuid = "f151be2c-9106-41f4-ab19-57ee4f262869"
version = "0.6.5"
weakdeps = ["Adapt"]

    [deps.EnzymeCore.extensions]
    AdaptExt = "Adapt"

[[deps.ExponentialUtilities]]
deps = ["Adapt", "ArrayInterface", "GPUArraysCore", "GenericSchur", "LinearAlgebra", "PrecompileTools", "Printf", "SparseArrays", "libblastrampoline_jll"]
git-tree-sha1 = "8e18940a5ba7f4ddb41fe2b79b6acaac50880a86"
uuid = "d4d017d3-3776-5f7e-afef-a10c40355c18"
version = "1.26.1"

[[deps.ExprTools]]
git-tree-sha1 = "27415f162e6028e81c72b82ef756bf321213b6ec"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.10"

[[deps.EzXML]]
deps = ["Printf", "XML2_jll"]
git-tree-sha1 = "380053d61bb9064d6aa4a9777413b40429c79901"
uuid = "8f5d6c58-4d21-5cfd-889c-e3ad7ee6a615"
version = "1.2.0"

[[deps.FastAlmostBandedMatrices]]
deps = ["ArrayInterface", "ArrayLayouts", "BandedMatrices", "ConcreteStructs", "LazyArrays", "LinearAlgebra", "MatrixFactorizations", "PrecompileTools", "Reexport"]
git-tree-sha1 = "178316d87f883f0702e79d9c83a8049484c9f619"
uuid = "9d29842c-ecb8-4973-b1e9-a27b1157504e"
version = "0.1.0"

[[deps.FastBroadcast]]
deps = ["ArrayInterface", "LinearAlgebra", "Polyester", "Static", "StaticArrayInterface", "StrideArraysCore"]
git-tree-sha1 = "a6e756a880fc419c8b41592010aebe6a5ce09136"
uuid = "7034ab61-46d4-4ed7-9d0f-46aef9175898"
version = "0.2.8"

[[deps.FastClosures]]
git-tree-sha1 = "acebe244d53ee1b461970f8910c235b259e772ef"
uuid = "9aa1b823-49e4-5ca5-8b0f-3971ec8bab6a"
version = "0.3.2"

[[deps.FastLapackInterface]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "d576a29bf8bcabf4b1deb9abe88a3d7f78306ab5"
uuid = "29a986be-02c6-4525-aec4-84b980013641"
version = "2.0.1"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "c5c28c245101bd59154f649e19b038d15901b5dc"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.16.2"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "9f00e42f8d99fdde64d40c8ea5d14269a2e2c1aa"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.21"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random"]
git-tree-sha1 = "5b93957f6dcd33fc343044af3d48c215be2562f1"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.9.3"
weakdeps = ["PDMats", "SparseArrays", "Statistics"]

    [deps.FillArrays.extensions]
    FillArraysPDMatsExt = "PDMats"
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStatisticsExt = "Statistics"

[[deps.FiniteDiff]]
deps = ["ArrayInterface", "LinearAlgebra", "Requires", "Setfield", "SparseArrays"]
git-tree-sha1 = "73d1214fec245096717847c62d389a5d2ac86504"
uuid = "6a86dc24-6348-571c-b903-95158fe2bd41"
version = "2.22.0"

    [deps.FiniteDiff.extensions]
    FiniteDiffBandedMatricesExt = "BandedMatrices"
    FiniteDiffBlockBandedMatricesExt = "BlockBandedMatrices"
    FiniteDiffStaticArraysExt = "StaticArrays"

    [deps.FiniteDiff.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions"]
git-tree-sha1 = "cf0fe81336da9fb90944683b8c41984b08793dad"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.36"
weakdeps = ["StaticArrays"]

    [deps.ForwardDiff.extensions]
    ForwardDiffStaticArraysExt = "StaticArrays"

[[deps.FunctionWrappers]]
git-tree-sha1 = "d62485945ce5ae9c0c48f124a84998d755bae00e"
uuid = "069b7b12-0de2-55c6-9aab-29f3d0a68a2e"
version = "1.1.3"

[[deps.FunctionWrappersWrappers]]
deps = ["FunctionWrappers"]
git-tree-sha1 = "b104d487b34566608f8b4e1c39fb0b10aa279ff8"
uuid = "77dc65aa-8811-40c2-897b-53d922fa7daf"
version = "0.1.3"

[[deps.Functors]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "166c544477f97bbadc7179ede1c1868e0e9b426b"
uuid = "d9f16b24-f501-4c13-a1f2-28368ffc5196"
version = "0.4.7"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "2d6ca471a6c7b536127afccfa7564b5b39227fe0"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.1.5"

[[deps.GenericSchur]]
deps = ["LinearAlgebra", "Printf"]
git-tree-sha1 = "fb69b2a645fa69ba5f474af09221b9308b160ce6"
uuid = "c145ed77-6b09-5dd9-b285-bf645a82121e"
version = "0.5.3"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "899050ace26649433ef1af25bc17a815b3db52b7"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.9.0"

[[deps.HDF5]]
deps = ["Compat", "HDF5_jll", "Libdl", "MPIPreferences", "Mmap", "Preferences", "Printf", "Random", "Requires", "UUIDs"]
git-tree-sha1 = "26407bd1c60129062cec9da63dc7d08251544d53"
uuid = "f67ccb44-e63f-5c2f-98bd-6dc0ccc4ba2f"
version = "0.17.1"

    [deps.HDF5.extensions]
    MPIExt = "MPI"

    [deps.HDF5.weakdeps]
    MPI = "da04e1cc-30fd-572f-bb4f-1f8673147195"

[[deps.HDF5_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "LazyArtifacts", "LibCURL_jll", "Libdl", "MPICH_jll", "MPIPreferences", "MPItrampoline_jll", "MicrosoftMPI_jll", "OpenMPI_jll", "OpenSSL_jll", "TOML", "Zlib_jll", "libaec_jll"]
git-tree-sha1 = "38c8874692d48d5440d5752d6c74b0c6b0b60739"
uuid = "0234f1f7-429e-5d53-9886-15a909be8d59"
version = "1.14.2+1"

[[deps.HostCPUFeatures]]
deps = ["BitTwiddlingConvenienceFunctions", "IfElse", "Libdl", "Static"]
git-tree-sha1 = "eb8fed28f4994600e29beef49744639d985a04b2"
uuid = "3e5b6fbb-0976-4d2c-9146-d79de83f2fb0"
version = "0.1.16"

[[deps.Hwloc_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "ca0f6bf568b4bfc807e7537f081c81e35ceca114"
uuid = "e33a78d0-f292-5ffc-b300-72abe9b543c8"
version = "2.10.0+0"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "OpenLibm_jll", "SpecialFunctions"]
git-tree-sha1 = "f218fe3736ddf977e0e772bc9a586b2383da2685"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.23"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "8b72179abc660bfab5e28472e019392b97d0985c"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.4"

[[deps.IfElse]]
git-tree-sha1 = "debdd00ffef04665ccbb3e150747a77560e8fad1"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.1"

[[deps.Inflate]]
git-tree-sha1 = "ea8031dea4aff6bd41f1df8f2fdfb25b33626381"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.4"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "9cc2baf75c6d09f9da536ddf58eb2f29dedaf461"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.0"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "5fdf2fe6724d8caabf43b557b84ce53f3b7e2f6b"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2024.0.2+0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Intervals]]
deps = ["Dates", "Printf", "RecipesBase", "Serialization", "TimeZones"]
git-tree-sha1 = "ac0aaa807ed5eaf13f67afe188ebc07e828ff640"
uuid = "d8418881-c3e1-53bb-8760-2df7ec849ed5"
version = "1.10.0"

[[deps.InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[deps.Ipopt]]
deps = ["Ipopt_jll", "LinearAlgebra", "MathOptInterface", "OpenBLAS32_jll", "PrecompileTools"]
git-tree-sha1 = "6600353576cee7e7388e57e94115f6aee034fb1c"
uuid = "b6b21f68-93f8-5de0-b562-5493be1d77c9"
version = "1.6.1"

[[deps.Ipopt_jll]]
deps = ["ASL_jll", "Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "MUMPS_seq_jll", "SPRAL_jll", "libblastrampoline_jll"]
git-tree-sha1 = "546c40fd3718c65d48296dd6cec98af9904e3ca4"
uuid = "9cc047cb-c261-5740-88fc-0cf96f7bdcc7"
version = "300.1400.1400+0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLD2]]
deps = ["FileIO", "MacroTools", "Mmap", "OrderedCollections", "Pkg", "PrecompileTools", "Printf", "Reexport", "Requires", "TranscodingStreams", "UUIDs"]
git-tree-sha1 = "5ea6acdd53a51d897672edb694e3cc2912f3f8a7"
uuid = "033835bb-8acc-5ee8-8aae-3f567f8a3819"
version = "0.4.46"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7e5d6779a1e09a36db2a7b6cff50942a0a7d0fca"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.5.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JuMP]]
deps = ["LinearAlgebra", "MacroTools", "MathOptInterface", "MutableArithmetics", "OrderedCollections", "PrecompileTools", "Printf", "SparseArrays"]
git-tree-sha1 = "4e44cff1595c6c02cdbca4e87ce376e63c33a584"
uuid = "4076af6c-e467-56ae-b986-b466b2749572"
version = "1.20.0"

    [deps.JuMP.extensions]
    JuMPDimensionalDataExt = "DimensionalData"

    [deps.JuMP.weakdeps]
    DimensionalData = "0703355e-b756-11e9-17c0-8b28908087d0"

[[deps.JumpProcesses]]
deps = ["ArrayInterface", "DataStructures", "DiffEqBase", "DocStringExtensions", "FunctionWrappers", "Graphs", "LinearAlgebra", "Markdown", "PoissonRandom", "Random", "RandomNumbers", "RecursiveArrayTools", "Reexport", "SciMLBase", "StaticArrays", "UnPack"]
git-tree-sha1 = "c451feb97251965a9fe40bacd62551a72cc5902c"
uuid = "ccbc3e58-028d-4f4c-8cd5-9ae44345cda5"
version = "9.10.1"
weakdeps = ["FastBroadcast"]

    [deps.JumpProcesses.extensions]
    JumpProcessFastBroadcastExt = "FastBroadcast"

[[deps.KLU]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse_jll"]
git-tree-sha1 = "884c2968c2e8e7e6bf5956af88cb46aa745c854b"
uuid = "ef3ab10e-7fda-4108-b977-705223b18434"
version = "0.4.1"

[[deps.Krylov]]
deps = ["LinearAlgebra", "Printf", "SparseArrays"]
git-tree-sha1 = "8a6837ec02fe5fb3def1abc907bb802ef11a0729"
uuid = "ba0b0d4f-ebba-5204-a429-3ac8c609bfb7"
version = "0.9.5"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d986ce2d884d49126836ea94ed5bfb0f12679713"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "15.0.7+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "50901ebc375ed41dbf8058da26f9de442febbbec"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.1"

[[deps.LayoutPointers]]
deps = ["ArrayInterface", "LinearAlgebra", "ManualMemory", "SIMDTypes", "Static", "StaticArrayInterface"]
git-tree-sha1 = "62edfee3211981241b57ff1cedf4d74d79519277"
uuid = "10f19ff3-798f-405d-979b-55457f8fc047"
version = "0.1.15"

[[deps.Lazy]]
deps = ["MacroTools"]
git-tree-sha1 = "1370f8202dac30758f3c345f9909b97f53d87d3f"
uuid = "50d2b5c4-7a5e-59d5-8109-a42b560f39c0"
version = "0.15.1"

[[deps.LazyArrays]]
deps = ["ArrayLayouts", "FillArrays", "LinearAlgebra", "MacroTools", "MatrixFactorizations", "SparseArrays"]
git-tree-sha1 = "9cfca23ab83b0dfac93cb1a1ef3331ab9fe596a5"
uuid = "5078a376-72f3-5289-bfd5-ec5146d43c02"
version = "1.8.3"
weakdeps = ["StaticArrays"]

    [deps.LazyArrays.extensions]
    LazyArraysStaticArraysExt = "StaticArrays"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LevyArea]]
deps = ["LinearAlgebra", "Random", "SpecialFunctions"]
git-tree-sha1 = "56513a09b8e0ae6485f34401ea9e2f31357958ec"
uuid = "2d8b4e74-eb68-11e8-0fb9-d5eb67b50637"
version = "1.0.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.4.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "f9557a255370125b405568f9767d6d195822a175"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.17.0+0"

[[deps.LineSearches]]
deps = ["LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "Printf"]
git-tree-sha1 = "7bbea35cec17305fc70a0e5b4641477dc0789d9d"
uuid = "d3d80556-e9d4-5f37-9878-2ab0fcc64255"
version = "7.2.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LinearMaps]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "9948d6f8208acfebc3e8cf4681362b2124339e7e"
uuid = "7a12625a-238d-50fd-b39a-03d52299707e"
version = "3.11.2"

    [deps.LinearMaps.extensions]
    LinearMapsChainRulesCoreExt = "ChainRulesCore"
    LinearMapsSparseArraysExt = "SparseArrays"
    LinearMapsStatisticsExt = "Statistics"

    [deps.LinearMaps.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.LinearSolve]]
deps = ["ArrayInterface", "ConcreteStructs", "DocStringExtensions", "EnumX", "FastLapackInterface", "GPUArraysCore", "InteractiveUtils", "KLU", "Krylov", "Libdl", "LinearAlgebra", "MKL_jll", "PrecompileTools", "Preferences", "RecursiveFactorization", "Reexport", "SciMLBase", "SciMLOperators", "Setfield", "SparseArrays", "Sparspak", "StaticArraysCore", "UnPack"]
git-tree-sha1 = "6f8e084deabe3189416c4e505b1c53e1b590cae8"
uuid = "7ed4a6bd-45f5-4d41-b270-4a48e9bafcae"
version = "2.22.1"

    [deps.LinearSolve.extensions]
    LinearSolveBandedMatricesExt = "BandedMatrices"
    LinearSolveBlockDiagonalsExt = "BlockDiagonals"
    LinearSolveCUDAExt = "CUDA"
    LinearSolveEnzymeExt = ["Enzyme", "EnzymeCore"]
    LinearSolveFastAlmostBandedMatricesExt = ["FastAlmostBandedMatrices"]
    LinearSolveHYPREExt = "HYPRE"
    LinearSolveIterativeSolversExt = "IterativeSolvers"
    LinearSolveKernelAbstractionsExt = "KernelAbstractions"
    LinearSolveKrylovKitExt = "KrylovKit"
    LinearSolveMetalExt = "Metal"
    LinearSolvePardisoExt = "Pardiso"
    LinearSolveRecursiveArrayToolsExt = "RecursiveArrayTools"

    [deps.LinearSolve.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockDiagonals = "0a1fb500-61f7-11e9-3c65-f5ef3456f9f0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    EnzymeCore = "f151be2c-9106-41f4-ab19-57ee4f262869"
    FastAlmostBandedMatrices = "9d29842c-ecb8-4973-b1e9-a27b1157504e"
    HYPRE = "b5ffcf37-a2bd-41ab-a3da-4bd9bc8ad771"
    IterativeSolvers = "42fd0dbc-a981-5370-80f2-aaf504508153"
    KernelAbstractions = "63c18a36-062a-441e-b654-da1e3ab1ce7c"
    KrylovKit = "0b1a1467-8014-51b9-945f-bf0ae24f4b77"
    Metal = "dde4c033-4e86-420c-a63e-0dd931031962"
    Pardiso = "46dd5b70-b6fb-5a00-ae2d-e8fea33afaf2"
    RecursiveArrayTools = "731186ca-8d62-57ce-b412-fbd966d074cd"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "18144f3e9cbe9b15b070288eef858f71b291ce37"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.27"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoopVectorization]]
deps = ["ArrayInterface", "CPUSummary", "CloseOpenIntervals", "DocStringExtensions", "HostCPUFeatures", "IfElse", "LayoutPointers", "LinearAlgebra", "OffsetArrays", "PolyesterWeave", "PrecompileTools", "SIMDTypes", "SLEEFPirates", "Static", "StaticArrayInterface", "ThreadingUtilities", "UnPack", "VectorizationBase"]
git-tree-sha1 = "0f5648fbae0d015e3abe5867bca2b362f67a5894"
uuid = "bdcacae8-1622-11e9-2a5c-532679323890"
version = "0.12.166"

    [deps.LoopVectorization.extensions]
    ForwardDiffExt = ["ChainRulesCore", "ForwardDiff"]
    SpecialFunctionsExt = "SpecialFunctions"

    [deps.LoopVectorization.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"

[[deps.MAT]]
deps = ["BufferedStreams", "CodecZlib", "HDF5", "SparseArrays"]
git-tree-sha1 = "ed1cf0a322d78cee07718bed5fd945e2218c35a1"
uuid = "23992714-dd62-5051-b70f-ba57cb901cac"
version = "0.10.6"

[[deps.METIS_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "1fd0a97409e418b78c53fac671cf4622efdf0f21"
uuid = "d00139f3-1899-568f-a2f0-47f597d42d70"
version = "5.1.2+0"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl"]
git-tree-sha1 = "72dc3cf284559eb8f53aa593fe62cb33f83ed0c0"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2024.0.0+0"

[[deps.MPICH_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Hwloc_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "MPIPreferences", "TOML"]
git-tree-sha1 = "656036b9ed6f942d35e536e249600bc31d0f9df8"
uuid = "7cb0a576-ebde-5e09-9194-50597f1243b4"
version = "4.2.0+0"

[[deps.MPIPreferences]]
deps = ["Libdl", "Preferences"]
git-tree-sha1 = "8f6af051b9e8ec597fa09d8885ed79fd582f33c9"
uuid = "3da0fdf6-3ccc-4f1b-acd9-58baa6c99267"
version = "0.1.10"

[[deps.MPItrampoline_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Hwloc_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "MPIPreferences", "TOML"]
git-tree-sha1 = "77c3bd69fdb024d75af38713e883d0f249ce19c2"
uuid = "f1f71cc9-e9ae-5b93-9b94-4fe0e1ad3748"
version = "5.3.2+0"

[[deps.MUMPS_seq_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "METIS_jll", "libblastrampoline_jll"]
git-tree-sha1 = "840b83c65b27e308095c139a457373850b2f5977"
uuid = "d7ed1dd3-d0ae-5e8e-bfb4-87a502085b8d"
version = "500.600.201+0"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "2fa9ee3e63fd3a4f7a9a4f4744a52f4856de82df"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.13"

[[deps.ManualMemory]]
git-tree-sha1 = "bcaef4fc7a0cfe2cba636d84cda54b5e4e4ca3cd"
uuid = "d125e4d3-2237-4719-b19c-fa641b8a4667"
version = "0.1.8"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MathOptInterface]]
deps = ["BenchmarkTools", "CodecBzip2", "CodecZlib", "DataStructures", "ForwardDiff", "JSON", "LinearAlgebra", "MutableArithmetics", "NaNMath", "OrderedCollections", "PrecompileTools", "Printf", "SparseArrays", "SpecialFunctions", "Test", "Unicode"]
git-tree-sha1 = "569a003f93d7c64068d3afaab908d21f67a22cd5"
uuid = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
version = "1.25.3"

[[deps.MatrixEquations]]
deps = ["LinearAlgebra", "LinearMaps"]
git-tree-sha1 = "f765b4eda3ea9be8e644b9127809ca5151f3d9ea"
uuid = "99c1a7ee-ab34-5fd5-8076-27c950a045f4"
version = "2.4.2"

[[deps.MatrixFactorizations]]
deps = ["ArrayLayouts", "LinearAlgebra", "Printf", "Random"]
git-tree-sha1 = "78f6e33434939b0ac9ba1df81e6d005ee85a7396"
uuid = "a3b82374-2e81-5b9e-98ce-41277c0e4c87"
version = "2.1.0"

[[deps.MaybeInplace]]
deps = ["ArrayInterface", "LinearAlgebra", "MacroTools", "SparseArrays"]
git-tree-sha1 = "a85c6a98c9e5a2a7046bc1bb89f28a3241e1de4d"
uuid = "bb5d69b7-63fc-4a16-80bd-7e42200c7bdb"
version = "0.1.1"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.MessyTimeSeries]]
deps = ["Dates", "Distributed", "Distributions", "LinearAlgebra", "Logging", "StableRNGs", "Statistics"]
git-tree-sha1 = "70a41f0d3c6e7e258a61c907816f4c2d84e28dcb"
uuid = "2a88db5c-15f1-4b3e-a070-d1159e8d76cc"
version = "0.2.6"

[[deps.MicrosoftMPI_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f12a29c4400ba812841c6ace3f4efbb6dbb3ba01"
uuid = "9237b28f-5490-5468-be7b-bb81f5f5e6cf"
version = "10.1.4+2"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.Mocking]]
deps = ["Compat", "ExprTools"]
git-tree-sha1 = "4cc0c5a83933648b615c36c2b956d94fda70641e"
uuid = "78c3b35d-d492-501b-9361-3d52fe80e533"
version = "0.7.7"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.MuladdMacro]]
git-tree-sha1 = "cac9cc5499c25554cba55cd3c30543cff5ca4fab"
uuid = "46d2c3a1-f734-5fdb-9937-b9b9aeba4221"
version = "0.2.4"

[[deps.MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "302fd161eb1c439e4115b51ae456da4e9984f130"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "1.4.1"

[[deps.NLSolversBase]]
deps = ["DiffResults", "Distributed", "FiniteDiff", "ForwardDiff"]
git-tree-sha1 = "a0b464d183da839699f4c79e7606d9d186ec172c"
uuid = "d41bc354-129a-5804-8e4c-c37616107c6c"
version = "7.8.3"

[[deps.NLsolve]]
deps = ["Distances", "LineSearches", "LinearAlgebra", "NLSolversBase", "Printf", "Reexport"]
git-tree-sha1 = "019f12e9a1a7880459d0173c182e6a99365d7ac1"
uuid = "2774e3e8-f4cf-5e23-947b-6d7e65073b56"
version = "4.5.1"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "0877504529a3e5c3343c6f8b4c0381e57e4387e4"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.2"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.NonlinearSolve]]
deps = ["ADTypes", "ArrayInterface", "ConcreteStructs", "DiffEqBase", "FastBroadcast", "FastClosures", "FiniteDiff", "ForwardDiff", "LazyArrays", "LineSearches", "LinearAlgebra", "LinearSolve", "MaybeInplace", "PrecompileTools", "Preferences", "Printf", "RecursiveArrayTools", "Reexport", "SciMLBase", "SimpleNonlinearSolve", "SparseArrays", "SparseDiffTools", "StaticArraysCore", "TimerOutputs"]
git-tree-sha1 = "b377521f4810057a99b0fa8cb7a1311c6cb1c8cd"
uuid = "8913a72c-1f9b-4ce2-8d82-65094dcecaec"
version = "3.5.6"

    [deps.NonlinearSolve.extensions]
    NonlinearSolveBandedMatricesExt = "BandedMatrices"
    NonlinearSolveFastLevenbergMarquardtExt = "FastLevenbergMarquardt"
    NonlinearSolveFixedPointAccelerationExt = "FixedPointAcceleration"
    NonlinearSolveLeastSquaresOptimExt = "LeastSquaresOptim"
    NonlinearSolveMINPACKExt = "MINPACK"
    NonlinearSolveNLsolveExt = "NLsolve"
    NonlinearSolveSIAMFANLEquationsExt = "SIAMFANLEquations"
    NonlinearSolveSpeedMappingExt = "SpeedMapping"
    NonlinearSolveSymbolicsExt = "Symbolics"
    NonlinearSolveZygoteExt = "Zygote"

    [deps.NonlinearSolve.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    FastLevenbergMarquardt = "7a0df574-e128-4d35-8cbd-3d84502bf7ce"
    FixedPointAcceleration = "817d07cb-a79a-5c30-9a31-890123675176"
    LeastSquaresOptim = "0fc2ff8b-aaa3-5acd-a817-1944a5e08891"
    MINPACK = "4854310b-de5a-5eb6-a2a5-c1dee2bd17f9"
    NLsolve = "2774e3e8-f4cf-5e23-947b-6d7e65073b56"
    SIAMFANLEquations = "084e46ad-d928-497d-ad5e-07fa361a48c4"
    SpeedMapping = "f1835b91-879b-4a3f-a438-e4baacf14412"
    Symbolics = "0c5d862f-8b57-4792-8d23-62f2024744c7"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.OffsetArrays]]
git-tree-sha1 = "6a731f2b5c03157418a20c12195eb4b74c8f8621"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.13.0"
weakdeps = ["Adapt"]

    [deps.OffsetArrays.extensions]
    OffsetArraysAdaptExt = "Adapt"

[[deps.OpenBLAS32_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6065c4cff8fee6c6770b277af45d5082baacdba1"
uuid = "656ef2d0-ae68-5445-9ca0-591084a874a2"
version = "0.3.24+0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+4"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+2"

[[deps.OpenMPI_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Hwloc_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "MPIPreferences", "PMIx_jll", "TOML", "Zlib_jll", "libevent_jll", "prrte_jll"]
git-tree-sha1 = "f46caf663e069027a06942d00dced37f1eb3d8ad"
uuid = "fe0851c0-eecd-5654-98d4-656369965a5c"
version = "5.0.2+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "60e3045590bd104a16fefb12836c00c0ef8c7f8c"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.0.13+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Optim]]
deps = ["Compat", "FillArrays", "ForwardDiff", "LineSearches", "LinearAlgebra", "MathOptInterface", "NLSolversBase", "NaNMath", "Parameters", "PositiveFactorizations", "Printf", "SparseArrays", "StatsBase"]
git-tree-sha1 = "d024bfb56144d947d4fafcd9cb5cafbe3410b133"
uuid = "429524aa-4258-5aef-a3af-852621145aeb"
version = "1.9.2"

[[deps.OrderedCollections]]
git-tree-sha1 = "dfdf5519f235516220579f949664f1bf44e741c5"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.3"

[[deps.OrdinaryDiffEq]]
deps = ["ADTypes", "Adapt", "ArrayInterface", "DataStructures", "DiffEqBase", "DocStringExtensions", "ExponentialUtilities", "FastBroadcast", "FastClosures", "FillArrays", "FiniteDiff", "ForwardDiff", "FunctionWrappersWrappers", "IfElse", "InteractiveUtils", "LineSearches", "LinearAlgebra", "LinearSolve", "Logging", "MacroTools", "MuladdMacro", "NonlinearSolve", "Polyester", "PreallocationTools", "PrecompileTools", "Preferences", "RecursiveArrayTools", "Reexport", "SciMLBase", "SciMLOperators", "SimpleNonlinearSolve", "SimpleUnPack", "SparseArrays", "SparseDiffTools", "StaticArrayInterface", "StaticArrays", "TruncatedStacktraces"]
git-tree-sha1 = "ed171bfea6156d6458007b19790a22f4754bd501"
uuid = "1dea7af3-3e70-54e6-95c3-0bf5283fa5ed"
version = "6.71.0"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "949347156c25054de2db3b166c52ac4728cbad65"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.31"

[[deps.PMIx_jll]]
deps = ["Artifacts", "Hwloc_jll", "JLLWrappers", "Libdl", "Zlib_jll", "libevent_jll"]
git-tree-sha1 = "8b3b19351fa24791f94d7ae85faf845ca1362541"
uuid = "32165bc3-0280-59bc-8c0b-c33b6203efab"
version = "4.2.7+0"

[[deps.PackageExtensionCompat]]
git-tree-sha1 = "fb28e33b8a95c4cee25ce296c817d89cc2e53518"
uuid = "65ce6f38-6b18-4e1d-a461-8949797d7930"
version = "1.0.2"
weakdeps = ["Requires", "TOML"]

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.PlotlyBase]]
deps = ["ColorSchemes", "Dates", "DelimitedFiles", "DocStringExtensions", "JSON", "LaTeXStrings", "Logging", "Parameters", "Pkg", "REPL", "Requires", "Statistics", "UUIDs"]
git-tree-sha1 = "56baf69781fc5e61607c3e46227ab17f7040ffa2"
uuid = "a03496cd-edff-5a9b-9e67-9cda94a718b5"
version = "0.8.19"

[[deps.PlutoPlotly]]
deps = ["AbstractPlutoDingetjes", "BaseDirs", "Colors", "Dates", "Downloads", "HypertextLiteral", "InteractiveUtils", "LaTeXStrings", "Markdown", "Pkg", "PlotlyBase", "Reexport", "TOML"]
git-tree-sha1 = "58dcb661ba1e58a13c7adce77435c3c6ac530ef9"
uuid = "8e989ff0-3d88-8e9f-f020-2b208a939ff0"
version = "0.4.4"

    [deps.PlutoPlotly.extensions]
    PlotlyKaleidoExt = "PlotlyKaleido"
    UnitfulExt = "Unitful"

    [deps.PlutoPlotly.weakdeps]
    PlotlyKaleido = "f2990250-8cf9-495f-b13a-cce12b45703c"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "211cdf570992b0d977fda3745f72772e0d5423f2"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.56"

[[deps.PoissonRandom]]
deps = ["Random"]
git-tree-sha1 = "a0f1159c33f846aa77c3f30ebbc69795e5327152"
uuid = "e409e4f3-bfea-5376-8464-e040bb5c01ab"
version = "0.4.4"

[[deps.Polyester]]
deps = ["ArrayInterface", "BitTwiddlingConvenienceFunctions", "CPUSummary", "IfElse", "ManualMemory", "PolyesterWeave", "Requires", "Static", "StaticArrayInterface", "StrideArraysCore", "ThreadingUtilities"]
git-tree-sha1 = "fca25670784a1ae44546bcb17288218310af2778"
uuid = "f517fe37-dbe3-4b94-8317-1923a5111588"
version = "0.7.9"

[[deps.PolyesterWeave]]
deps = ["BitTwiddlingConvenienceFunctions", "CPUSummary", "IfElse", "Static", "ThreadingUtilities"]
git-tree-sha1 = "240d7170f5ffdb285f9427b92333c3463bf65bf6"
uuid = "1d0040c9-8b98-4ee7-8388-3f51789ca0ad"
version = "0.2.1"

[[deps.Polynomials]]
deps = ["Intervals", "LinearAlgebra", "MutableArithmetics", "RecipesBase"]
git-tree-sha1 = "a1f7f4e41404bed760213ca01d7f384319f717a5"
uuid = "f27b6e38-b328-58d1-80ce-0feddd5e7a45"
version = "2.0.25"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "36d8b4b899628fb92c2749eb488d884a926614d3"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.3"

[[deps.PositiveFactorizations]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "17275485f373e6673f7e7f97051f703ed5b15b20"
uuid = "85a6dd25-e78a-55b7-8502-1745935b8125"
version = "0.2.4"

[[deps.PreallocationTools]]
deps = ["Adapt", "ArrayInterface", "ForwardDiff"]
git-tree-sha1 = "b6665214f2d0739f2d09a17474dd443b9139784a"
uuid = "d236fae5-4411-538c-8e31-a6e3d9e00b46"
version = "0.4.20"

    [deps.PreallocationTools.extensions]
    PreallocationToolsReverseDiffExt = "ReverseDiff"

    [deps.PreallocationTools.weakdeps]
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "03b4c25b43cb84cee5c90aa9b5ea0a78fd848d2f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00805cd429dcb4870060ff49ef443486c262e38e"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.1"

[[deps.PrettyTables]]
deps = ["Crayons", "LaTeXStrings", "Markdown", "PrecompileTools", "Printf", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "88b895d13d53b5577fd53379d913b9ab9ac82660"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.3.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "9b23c31e76e333e6fb4c1595ae6afa74966a729e"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.9.4"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Random123]]
deps = ["Random", "RandomNumbers"]
git-tree-sha1 = "c860e84651f58ce240dd79e5d9e055d55234c35a"
uuid = "74087812-796a-5b5d-8853-05524746bad3"
version = "1.6.2"

[[deps.RandomNumbers]]
deps = ["Random", "Requires"]
git-tree-sha1 = "043da614cc7e95c703498a491e2c21f58a2b8111"
uuid = "e6cf234a-135c-5ec9-84dd-332b85af5143"
version = "1.5.3"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.RecursiveArrayTools]]
deps = ["Adapt", "ArrayInterface", "DocStringExtensions", "GPUArraysCore", "IteratorInterfaceExtensions", "LinearAlgebra", "RecipesBase", "SparseArrays", "StaticArraysCore", "Statistics", "SymbolicIndexingInterface", "Tables"]
git-tree-sha1 = "09c906ce9fa905d40e0706cdb62422422091c22f"
uuid = "731186ca-8d62-57ce-b412-fbd966d074cd"
version = "3.8.1"

    [deps.RecursiveArrayTools.extensions]
    RecursiveArrayToolsFastBroadcastExt = "FastBroadcast"
    RecursiveArrayToolsForwardDiffExt = "ForwardDiff"
    RecursiveArrayToolsMeasurementsExt = "Measurements"
    RecursiveArrayToolsMonteCarloMeasurementsExt = "MonteCarloMeasurements"
    RecursiveArrayToolsReverseDiffExt = ["ReverseDiff", "Zygote"]
    RecursiveArrayToolsTrackerExt = "Tracker"
    RecursiveArrayToolsZygoteExt = "Zygote"

    [deps.RecursiveArrayTools.weakdeps]
    FastBroadcast = "7034ab61-46d4-4ed7-9d0f-46aef9175898"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    MonteCarloMeasurements = "0987c9cc-fe09-11e8-30f0-b96dd679fdca"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.RecursiveFactorization]]
deps = ["LinearAlgebra", "LoopVectorization", "Polyester", "PrecompileTools", "StrideArraysCore", "TriangularSolve"]
git-tree-sha1 = "8bc86c78c7d8e2a5fe559e3721c0f9c9e303b2ed"
uuid = "f2c3362d-daeb-58d1-803e-2bc74f2840b4"
version = "0.2.21"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.ResettableStacks]]
deps = ["StaticArrays"]
git-tree-sha1 = "256eeeec186fa7f26f2801732774ccf277f05db9"
uuid = "ae5879a3-cd67-5da8-be7f-38c6eb64a37b"
version = "1.1.1"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "f65dcb5fa46aee0cf9ed6274ccbd597adc49aa7b"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.1"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6ed52fdd3382cf21947b15e8870ac0ddbff736da"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.4.0+0"

[[deps.RuntimeGeneratedFunctions]]
deps = ["ExprTools", "SHA", "Serialization"]
git-tree-sha1 = "6aacc5eefe8415f47b3e34214c1d79d2674a0ba2"
uuid = "7e49a35a-f44a-4d26-94aa-eba1b4ca6b47"
version = "0.5.12"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SIMDTypes]]
git-tree-sha1 = "330289636fb8107c5f32088d2741e9fd7a061a5c"
uuid = "94e857df-77ce-4151-89e5-788b33177be4"
version = "0.1.0"

[[deps.SLEEFPirates]]
deps = ["IfElse", "Static", "VectorizationBase"]
git-tree-sha1 = "3aac6d68c5e57449f5b9b865c9ba50ac2970c4cf"
uuid = "476501e8-09a2-5ece-8869-fb82de89a1fa"
version = "0.6.42"

[[deps.SPRAL_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Hwloc_jll", "JLLWrappers", "Libdl", "METIS_jll", "libblastrampoline_jll"]
git-tree-sha1 = "34b9dacd687cace8aa4d550e3e9bb8615f1a61e9"
uuid = "319450e9-13b8-58e8-aa9f-8fd1420848ab"
version = "2024.1.18+0"

[[deps.SciMLBase]]
deps = ["ADTypes", "ArrayInterface", "CommonSolve", "ConstructionBase", "Distributed", "DocStringExtensions", "EnumX", "FillArrays", "FunctionWrappersWrappers", "IteratorInterfaceExtensions", "LinearAlgebra", "Logging", "Markdown", "PrecompileTools", "Preferences", "Printf", "RecipesBase", "RecursiveArrayTools", "Reexport", "RuntimeGeneratedFunctions", "SciMLOperators", "StaticArraysCore", "Statistics", "SymbolicIndexingInterface", "Tables", "TruncatedStacktraces"]
git-tree-sha1 = "a123011b1711f3449bc4e5d66746be5725af92fd"
uuid = "0bca4576-84f4-4d90-8ffe-ffa030f20462"
version = "2.26.0"

    [deps.SciMLBase.extensions]
    SciMLBaseChainRulesCoreExt = "ChainRulesCore"
    SciMLBaseMakieExt = "Makie"
    SciMLBasePartialFunctionsExt = "PartialFunctions"
    SciMLBasePyCallExt = "PyCall"
    SciMLBasePythonCallExt = "PythonCall"
    SciMLBaseRCallExt = "RCall"
    SciMLBaseZygoteExt = "Zygote"

    [deps.SciMLBase.weakdeps]
    ChainRules = "082447d4-558c-5d27-93f4-14fc19e9eca2"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
    PartialFunctions = "570af359-4316-4cb7-8c74-252c00c2016b"
    PyCall = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"
    PythonCall = "6099a3de-0909-46bc-b1f4-468b9a2dfc0d"
    RCall = "6f49c342-dc21-5d91-9882-a32aef131414"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.SciMLOperators]]
deps = ["ArrayInterface", "DocStringExtensions", "Lazy", "LinearAlgebra", "Setfield", "SparseArrays", "StaticArraysCore", "Tricks"]
git-tree-sha1 = "51ae235ff058a64815e0a2c34b1db7578a06813d"
uuid = "c0aeaf25-5076-4817-a8d5-81caf7dfa961"
version = "0.3.7"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "3bac05bc7e74a75fd9cba4295cde4045d9fe2386"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.1"

[[deps.SeasonalTrendLoess]]
deps = ["Statistics"]
git-tree-sha1 = "839dcd8152dc20663349781f7a7e8cf3d3009673"
uuid = "42fb36cb-998a-4034-bf40-4eee476c43a1"
version = "0.1.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "0e7508ff27ba32f26cd459474ca2ede1bc10991f"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "e2cc6d8c88613c05e1defb55170bf5ff211fbeac"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.1"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.ShiftedArrays]]
git-tree-sha1 = "22395afdcf37d6709a5a0766cc4a5ca52cb85ea0"
uuid = "1277b4bf-5013-50f5-be3d-901d8477a67a"
version = "1.0.0"

[[deps.SimpleNonlinearSolve]]
deps = ["ADTypes", "ArrayInterface", "ConcreteStructs", "DiffEqBase", "FastClosures", "FiniteDiff", "ForwardDiff", "LinearAlgebra", "MaybeInplace", "PrecompileTools", "Reexport", "SciMLBase", "StaticArraysCore"]
git-tree-sha1 = "873a1bf90744acfa615e45cd5dddfd0ee89a094f"
uuid = "727e6d20-b764-4bd8-a329-72de5adea6c7"
version = "1.5.0"

    [deps.SimpleNonlinearSolve.extensions]
    SimpleNonlinearSolveChainRulesCoreExt = "ChainRulesCore"
    SimpleNonlinearSolvePolyesterForwardDiffExt = "PolyesterForwardDiff"
    SimpleNonlinearSolveStaticArraysExt = "StaticArrays"

    [deps.SimpleNonlinearSolve.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    PolyesterForwardDiff = "98d1487c-24ca-40b6-b7ab-df2af84e126b"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.SimpleUnPack]]
git-tree-sha1 = "58e6353e72cde29b90a69527e56df1b5c3d8c437"
uuid = "ce78b400-467f-4804-87d8-8f486da07d0a"
version = "1.1.0"

[[deps.SkipNan]]
git-tree-sha1 = "b07be17ad1c4dd3e2d11aff5aa06157838ee6a6a"
uuid = "aed68c70-c8b0-4309-8cd1-d392a74f991a"
version = "0.2.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

[[deps.SparseDiffTools]]
deps = ["ADTypes", "Adapt", "ArrayInterface", "Compat", "DataStructures", "FiniteDiff", "ForwardDiff", "Graphs", "LinearAlgebra", "PackageExtensionCompat", "Random", "Reexport", "SciMLOperators", "Setfield", "SparseArrays", "StaticArrayInterface", "StaticArrays", "Tricks", "UnPack", "VertexSafeGraphs"]
git-tree-sha1 = "a616ac46c38da60ac05cecf52064d44732edd05e"
uuid = "47a9eef4-7e08-11e9-0b38-333d64bd3804"
version = "2.17.0"

    [deps.SparseDiffTools.extensions]
    SparseDiffToolsEnzymeExt = "Enzyme"
    SparseDiffToolsPolyesterExt = "Polyester"
    SparseDiffToolsPolyesterForwardDiffExt = "PolyesterForwardDiff"
    SparseDiffToolsSymbolicsExt = "Symbolics"
    SparseDiffToolsZygoteExt = "Zygote"

    [deps.SparseDiffTools.weakdeps]
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    Polyester = "f517fe37-dbe3-4b94-8317-1923a5111588"
    PolyesterForwardDiff = "98d1487c-24ca-40b6-b7ab-df2af84e126b"
    Symbolics = "0c5d862f-8b57-4792-8d23-62f2024744c7"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.Sparspak]]
deps = ["Libdl", "LinearAlgebra", "Logging", "OffsetArrays", "Printf", "SparseArrays", "Test"]
git-tree-sha1 = "342cf4b449c299d8d1ceaf00b7a49f4fbc7940e7"
uuid = "e56a9233-b9d6-4f03-8d0f-1825330902ac"
version = "0.3.9"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "e2cfc4012a19088254b3950b85c3c1d8882d864d"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.3.1"

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

    [deps.SpecialFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"

[[deps.StableRNGs]]
deps = ["Random", "Test"]
git-tree-sha1 = "ddc1a7b85e760b5285b50b882fa91e40c603be47"
uuid = "860ef19b-820b-49d6-a774-d7a799459cd3"
version = "1.0.1"

[[deps.StateSpaceModels]]
deps = ["Distributions", "LinearAlgebra", "MatrixEquations", "Optim", "OrderedCollections", "Polynomials", "Printf", "RecipesBase", "SeasonalTrendLoess", "ShiftedArrays", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "1fca6ae24e606629e0701a347831a675a291e69b"
uuid = "99342f36-827c-5390-97c9-d7f9ee765c78"
version = "0.6.7"

[[deps.Static]]
deps = ["IfElse"]
git-tree-sha1 = "d2fdac9ff3906e27f7a618d47b676941baa6c80c"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "0.8.10"

[[deps.StaticArrayInterface]]
deps = ["ArrayInterface", "Compat", "IfElse", "LinearAlgebra", "PrecompileTools", "Requires", "SparseArrays", "Static", "SuiteSparse"]
git-tree-sha1 = "5d66818a39bb04bf328e92bc933ec5b4ee88e436"
uuid = "0d7ed370-da01-4f52-bd93-41d350b8b718"
version = "1.5.0"
weakdeps = ["OffsetArrays", "StaticArrays"]

    [deps.StaticArrayInterface.extensions]
    StaticArrayInterfaceOffsetArraysExt = "OffsetArrays"
    StaticArrayInterfaceStaticArraysExt = "StaticArrays"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "7b0e9c14c624e435076d19aea1e5cbdec2b9ca37"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.2"

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

    [deps.StaticArrays.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StaticArraysCore]]
git-tree-sha1 = "36b3d696ce6366023a0ea192b4cd442268995a0d"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.2"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.10.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[deps.StatsFuns]]
deps = ["HypergeometricFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "cef0472124fab0695b58ca35a77c6fb942fdab8a"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.3.1"

    [deps.StatsFuns.extensions]
    StatsFunsChainRulesCoreExt = "ChainRulesCore"
    StatsFunsInverseFunctionsExt = "InverseFunctions"

    [deps.StatsFuns.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.SteadyStateDiffEq]]
deps = ["ConcreteStructs", "DiffEqBase", "DiffEqCallbacks", "LinearAlgebra", "Reexport", "SciMLBase"]
git-tree-sha1 = "a735fd5053724cf4de31c81b4e2cc429db844be5"
uuid = "9672c7b4-1e72-59bd-8a11-6ac3964bc41f"
version = "2.0.1"

[[deps.StochasticDiffEq]]
deps = ["Adapt", "ArrayInterface", "DataStructures", "DiffEqBase", "DiffEqNoiseProcess", "DocStringExtensions", "FiniteDiff", "ForwardDiff", "JumpProcesses", "LevyArea", "LinearAlgebra", "Logging", "MuladdMacro", "NLsolve", "OrdinaryDiffEq", "Random", "RandomNumbers", "RecursiveArrayTools", "Reexport", "SciMLBase", "SciMLOperators", "SparseArrays", "SparseDiffTools", "StaticArrays", "UnPack"]
git-tree-sha1 = "f5eb6f4794a2a56d6b9d3dcdb9d6cb217a2ac660"
uuid = "789caeaf-c7a9-5a7d-9973-96adeb23e2a0"
version = "6.65.0"

[[deps.StrideArraysCore]]
deps = ["ArrayInterface", "CloseOpenIntervals", "IfElse", "LayoutPointers", "ManualMemory", "SIMDTypes", "Static", "StaticArrayInterface", "ThreadingUtilities"]
git-tree-sha1 = "d6415f66f3d89c615929af907fdc6a3e17af0d8c"
uuid = "7792a7ef-975c-4747-a70f-980b88e8d1da"
version = "0.5.2"

[[deps.StringManipulation]]
deps = ["PrecompileTools"]
git-tree-sha1 = "a04cabe79c5f01f4d723cc6704070ada0b9d46d5"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.3.4"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.2.1+1"

[[deps.Sundials]]
deps = ["CEnum", "DataStructures", "DiffEqBase", "Libdl", "LinearAlgebra", "Logging", "PrecompileTools", "Reexport", "SciMLBase", "SparseArrays", "Sundials_jll"]
git-tree-sha1 = "e15f5a73f0d14b9079b807a9d1dac13e4302e997"
uuid = "c3572dad-4567-51f8-b174-8c6c989267f4"
version = "4.24.0"

[[deps.Sundials_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "SuiteSparse_jll", "libblastrampoline_jll"]
git-tree-sha1 = "ba4d38faeb62de7ef47155ed321dce40a549c305"
uuid = "fb77eaff-e24c-56d4-86b1-d163f2edb164"
version = "5.2.2+0"

[[deps.SymbolicIndexingInterface]]
git-tree-sha1 = "dc7186d456f9ff2bef0cb754a59758920f0b2382"
uuid = "2efcf032-c050-4f8e-a9bb-153293bab1f5"
version = "0.3.6"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TZJData]]
deps = ["Artifacts"]
git-tree-sha1 = "b69f8338df046774bd975b13be9d297eca5efacb"
uuid = "dc5dba14-91b3-4cab-a142-028a31da12f7"
version = "1.1.0+2023d"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "cb76cf677714c095e535e3501ac7954732aeea2d"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.11.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.ThreadingUtilities]]
deps = ["ManualMemory"]
git-tree-sha1 = "eda08f7e9818eb53661b3deb74e3159460dfbc27"
uuid = "8290d209-cae3-49c0-8002-c8c24d57dab5"
version = "0.5.2"

[[deps.TimeZones]]
deps = ["Artifacts", "Dates", "Downloads", "InlineStrings", "LazyArtifacts", "Mocking", "Printf", "Scratch", "TZJData", "Unicode", "p7zip_jll"]
git-tree-sha1 = "89e64d61ef3cd9e80f7fc12b7d13db2d75a23c03"
uuid = "f269a46b-ccf7-5d73-abea-4c690281aa53"
version = "1.13.0"
weakdeps = ["RecipesBase"]

    [deps.TimeZones.extensions]
    TimeZonesRecipesBaseExt = "RecipesBase"

[[deps.TimerOutputs]]
deps = ["ExprTools", "Printf"]
git-tree-sha1 = "f548a9e9c490030e545f72074a41edfd0e5bcdd7"
uuid = "a759f4b9-e2f1-59dc-863e-4aeb61b1ea8f"
version = "0.5.23"

[[deps.TranscodingStreams]]
git-tree-sha1 = "54194d92959d8ebaa8e26227dbe3cdefcdcd594f"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.10.3"
weakdeps = ["Random", "Test"]

    [deps.TranscodingStreams.extensions]
    TestExt = ["Test", "Random"]

[[deps.TriangularSolve]]
deps = ["CloseOpenIntervals", "IfElse", "LayoutPointers", "LinearAlgebra", "LoopVectorization", "Polyester", "Static", "VectorizationBase"]
git-tree-sha1 = "fadebab77bf3ae041f77346dd1c290173da5a443"
uuid = "d5829a12-d9aa-46ab-831f-fb7c9ab06edf"
version = "0.1.20"

[[deps.Tricks]]
git-tree-sha1 = "eae1bb484cd63b36999ee58be2de6c178105112f"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.8"

[[deps.TruncatedStacktraces]]
deps = ["InteractiveUtils", "MacroTools", "Preferences"]
git-tree-sha1 = "ea3e54c2bdde39062abf5a9758a23735558705e1"
uuid = "781d530d-4396-4725-bb49-402e4bee1e77"
version = "1.4.0"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.VectorizationBase]]
deps = ["ArrayInterface", "CPUSummary", "HostCPUFeatures", "IfElse", "LayoutPointers", "Libdl", "LinearAlgebra", "SIMDTypes", "Static", "StaticArrayInterface"]
git-tree-sha1 = "7209df901e6ed7489fe9b7aa3e46fb788e15db85"
uuid = "3d5dd08c-fd9d-11e8-17fa-ed2836048c2f"
version = "0.21.65"

[[deps.VertexSafeGraphs]]
deps = ["Graphs"]
git-tree-sha1 = "8351f8d73d7e880bfc042a8b6922684ebeafb35c"
uuid = "19fa3120-7c27-5ec5-8db8-b0b0aa330d6f"
version = "0.2.0"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.WorkerUtilities]]
git-tree-sha1 = "cd1659ba0d57b71a464a29e64dbc67cfe83d54e7"
uuid = "76eceee3-57b5-4d4a-8e66-0e911cebbf60"
version = "1.6.1"

[[deps.XLSX]]
deps = ["Artifacts", "Dates", "EzXML", "Printf", "Tables", "ZipFile"]
git-tree-sha1 = "319b05e790046f18f12b8eae542546518ef1a88f"
uuid = "fdbf4ff8-1666-58a4-91e7-1b58723a45e0"
version = "0.10.1"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "801cbe47eae69adc50f36c3caec4758d2650741b"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.12.2+0"

[[deps.ZipFile]]
deps = ["Libdl", "Printf", "Zlib_jll"]
git-tree-sha1 = "f492b7fe1698e623024e873244f10d89c95c340a"
uuid = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"
version = "0.10.1"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.libaec_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "eddd19a8dea6b139ea97bdc8a0e2667d4b661720"
uuid = "477f73a3-ac25-53e9-8cc3-50b2fa2566f0"
version = "1.0.6+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"

[[deps.libevent_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "OpenSSL_jll"]
git-tree-sha1 = "f04ec6d9a186115fb38f858f05c0c4e1b7fc9dcb"
uuid = "1080aeaf-3a6a-583e-a51c-c537b09f60ec"
version = "2.1.13+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"

[[deps.prrte_jll]]
deps = ["Artifacts", "Hwloc_jll", "JLLWrappers", "Libdl", "PMIx_jll", "libevent_jll"]
git-tree-sha1 = "5adb2d7a18a30280feb66cad6f1a1dfdca2dc7b0"
uuid = "eb928a42-fffd-568d-ab9c-3f5d54fc65b9"
version = "3.0.2+0"
"""

# ╔═╡ Cell order:
# ╟─9747955b-9aae-49f9-867b-417f8d854c74
# ╟─65264515-eb94-4e01-8d55-9ae8c218c735
# ╟─8ad5e30c-a496-4917-83bd-5a184abae2ac
# ╟─4af67516-b877-42f1-93ab-8a885d86d41b
# ╟─8dc7f570-d344-4bb5-a90b-fc0e92a42bdb
# ╟─0c5d6679-f09f-44ea-ad70-a8bfc59e909c
# ╠═77645cc1-6b40-4550-a7fc-c7f90e2bda28
# ╟─5dfd12e1-f284-4e3b-ae05-3b25d9a5e9d7
# ╟─c12e68b7-2f66-496e-96e8-1d15823721e3
# ╠═1b8d063a-fbe1-4ceb-93b6-d500857a2cad
# ╟─a014af65-1b5b-4551-9e05-5d46e2277b43
# ╠═a7f1e727-5068-4109-9f94-2f80c8571e83
# ╟─5c6a2a41-7ba6-4d2f-9b06-052eef3c9dfd
# ╠═fcb83aa4-8b67-49d1-a242-8e273432630b
# ╟─97e77ac8-597b-4f69-8e89-c11cecb57ee1
# ╠═efe5d7d2-050a-4e40-95ba-6874bdad9292
# ╟─4396b45f-2946-4d55-b1de-798534ef3847
# ╠═9d62d9c2-7516-4433-8fdc-59692b061bf8
# ╟─d14ca3ba-7afe-4c8e-b10f-ab0419229f79
# ╠═cd685411-3fe7-47d1-95a1-273729d964fb
# ╟─3268c803-3af8-47d1-a0fa-5b204a18bf87
# ╟─9eb1b308-6ca0-45b8-8134-743137f1d4cb
# ╟─fd1d1975-af46-4668-a3d0-32e3dea9cdbf
# ╟─448ab989-73a1-45b2-9b15-7682ead174dd
# ╟─94c65e02-593d-4fd6-a52b-075cd0922d49
# ╟─b1ad96b6-24eb-4d4c-9aa3-c36bfd4bbf7e
# ╟─e99338ea-9792-4ff5-bedb-7c590816d06c
# ╟─fd0eb755-290f-4e99-9bfe-7557f4b7e93b
# ╟─f55c6672-791f-4062-95d6-add0cbafa7c3
# ╟─b47f6864-64ae-48bf-984b-d5307cafe705
# ╟─c192ee1e-9a12-4119-a054-d52b4164b254
# ╟─ef5ff9e0-812f-492c-9307-c870c54c4418
# ╟─ca8893fd-d745-4fe4-bcf1-3745a8451b09
# ╟─d84099c1-3af4-4e96-9ae7-885954c605e1
# ╟─2281846a-9323-4323-966d-0b92acd5179f
# ╟─b6d7a9ef-fc95-40db-8f6e-bd9f21e42e0c
# ╟─2fee660b-5c5c-4f85-9d1e-1b45790827b9
# ╟─e10ee5be-f458-4d41-b3ab-193868566f0e
# ╟─22889383-3b4a-4e57-b356-582a0952ffa3
# ╟─c12c5796-24e9-4658-8dd4-fded7a873e56
# ╟─a3223983-61b4-435d-b57f-94f9bf359890
# ╟─5c8b773b-02e9-4101-837e-b34631fcdada
# ╟─7611ab55-3866-4e06-be4a-107be7f84a6e
# ╟─2adbaca0-40a2-4508-9ec4-99e2c54ad1aa
# ╟─06c4f2dc-6588-41b2-90dc-d4ee82ae55b4
# ╟─f8b2171b-a842-4e98-bf67-ac260b431e5a
# ╟─c19c45d5-ce9d-4176-86e8-6caa3d2074ba
# ╟─1e1e48c7-b3c5-4661-9dec-e820846ce12b
# ╟─26bd47f0-05a9-448d-8270-32c3b5463560
# ╠═a5f5bc09-2ab8-4f35-a0f0-2f99dfa38701
# ╠═d4901f31-4958-4726-b9f8-617dc3c5e1ce
# ╠═279ceff9-d1fc-49ee-bfe9-6b01faa6e8d8
# ╠═2ecd61dc-4a0b-4149-809c-6192e5e3b946
# ╠═03a5025f-99d0-4fad-b480-a0e51d40583c
# ╠═4aae45e1-2199-4f39-9c71-349516419767
# ╟─915763b8-98c4-4b11-bf55-8298d9b46865
# ╠═a991e832-106a-416a-8c81-a2e06f03c3b2
# ╟─833410b3-5fba-41ef-a890-4870f3b6fae8
# ╠═7c9402b5-53c8-4d1a-84b4-2eda256f774e
# ╟─d2073599-f56c-4020-8ae6-d9ea900c6349
# ╟─e550c3f8-6654-4c65-897f-aeaa1f03b719
# ╠═4977aea3-982c-4a92-ae48-3bbac1362b94
# ╟─dcec7778-a338-4a27-9dff-0dba2c44905a
# ╟─9bcf5636-af5a-421c-ba2d-49e77574abf6
# ╟─7108d45f-552e-44ff-a332-cb2956cfab0f
# ╟─48d8c33d-9dcd-4804-8fc4-c8d0c891c023
# ╟─36bf19e0-05b5-4a31-9d2a-b8cb97178641
# ╟─f5ab47e5-c784-40b4-9a78-5ab918f0b8a6
# ╟─ff213ef6-336d-4d77-966d-4247f4f914ac
# ╟─c97cf677-ceb9-4353-9ceb-770c8053d99a
# ╟─3c28deaa-16a7-4b4f-a34b-964259c5c08c
# ╟─e1d73e95-23ff-428f-8dfc-081393936547
# ╟─a45db449-1fbf-479b-bbb6-a14d4edc4708
# ╟─e9e69514-a0cc-462a-a206-92a66828e230
# ╟─f44de9fc-18e1-4b90-86dc-627c997e2fd0
# ╠═d52558e5-30e9-43e3-a55d-63b90d98065a
# ╠═a027c834-1151-4762-80ff-ea9d38928a1b
# ╠═60ace95d-1c81-420c-95ec-b7a5437f8f06
# ╠═25752a37-039f-43ce-86c1-b465e18a8a00
# ╠═baa6b135-fde1-483d-ab20-12bc670c750e
# ╠═85c930f9-c2de-449d-861b-8d3ba332941e
# ╟─79cbd721-2a16-464f-a7d0-a065c97b6721
# ╠═2da60c13-458f-48f5-a6ec-de91fc710224
# ╠═36c1b787-508b-4f1b-9e1c-6e805dd4e469
# ╟─4d6397ac-5869-42ef-9988-c54d71cd3675
# ╟─d8a89820-49a0-4ec0-90d3-89b655f3f52d
# ╟─fd7b20a0-6921-4eb7-84df-54a55186d911
# ╠═c1220fee-d686-445b-ac85-c7d7b5413f38
# ╟─c29942cf-5a59-4b21-9242-db3e7f5e7dd8
# ╠═998cb498-22bd-4a9a-aafb-c16b2272679e
# ╠═dc929ca4-3df4-4c16-912d-3931c709067f
# ╠═db857a08-693f-44aa-be6d-5ebf05c6acf3
# ╟─db399be8-c655-40b2-b55c-9f5cee33735a
# ╠═3992c8e2-ea5c-4eda-9e68-9b0932fa9ff1
# ╠═216ce65b-2c60-41b1-a1b8-b0808435cf72
# ╟─785400a5-1577-4779-a93e-e5e84b854038
# ╠═10f6c5d8-2dbb-422d-9726-a81f6c06164e
# ╟─9bfd4119-dfb6-494d-b396-295a9a92ddbf
# ╠═917e0469-28ca-4bae-8d8a-b139a12fe0c0
# ╟─24eee1af-6cfe-4b63-89e7-5add1b2399a4
# ╠═775fbcd7-77b4-4b54-8cde-c4a136a33bd4
# ╠═ee1a1abb-2abd-4ee2-a72c-ac3c0d9247c7
# ╟─2978ac5a-3a59-47fa-ace3-f0910ade0b0e
# ╠═f3a98e92-e257-443f-b809-02c2afcefe42
# ╟─bf1a1ae1-b2f0-4fb2-9b29-09bad0c2110e
# ╠═c994e08d-dddb-4e7c-a9a7-b34dbb28f49f
# ╠═09ff7dbf-268e-48c3-bc08-66d5e0bf47d1
# ╠═438a8174-be9c-40dd-9490-b7d2e1999141
# ╠═74528d4d-9c5a-47f7-a9ec-d1910074e702
# ╟─0eb4bd4b-3f09-4afb-915a-c46ab75cabd7
# ╠═3595b148-2c9e-4581-9a7e-0e9748e4d106
# ╠═a1b1270d-5711-4531-9f33-53ae3ea2cbd6
# ╠═9be06855-4722-470d-bfe5-d9491c9bcb51
# ╟─b282d5e0-1ed7-479a-9a01-30713b05742b
# ╠═e24ae473-3441-4580-80af-25fc8dfcf23b
# ╠═055cc198-5fd4-444b-b5a9-0bf7bc25baea
# ╠═9bad981f-cdef-4828-a5cf-eb2efc356b35
# ╟─61ef1273-0511-4c77-be27-8dee734d2e7c
# ╠═4e56cadc-cd0a-11ee-012a-2fc721cec33f
# ╠═a0d48ab4-a699-463d-8534-713f041a069e
# ╟─ac3e7af7-f6b3-449f-a006-e392848c151e
# ╠═66d42767-7faf-4c67-84fe-8d49913a199b
# ╠═45d9cd2d-bd6b-488f-ad99-d67751081bf6
# ╠═c9d7eca9-1a70-4698-b98a-f05689dd8018
# ╠═1c5cf467-2050-479d-b07d-26bb7765482e
# ╠═dbf45b45-4e4d-4945-ad11-3eeac47da5d3
# ╠═b2e2c39c-38ef-42fb-a7ea-feca602ac793
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
