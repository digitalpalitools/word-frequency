<#
- TODO:
  - "-"" in the exclusion character class
  - \(.*\) in the exclusion character class
  - the brackets and everything in them can be excluded - exclude () and everything in them just for this file or all across?
  - everything marked with <hi rend="bold"> should be included
  - note within hi-bold <p rend="gatha1"><hi rend="bold">‘‘Dhīre</hi><pb ed="P" n="0.0124" /><hi rend="bold"> nirodhaṃ phusehi <note>phussehi (sī.)</note>, saññāvūpasamaṃ sukhaṃ;</hi></p>
  - [TODO] any line in any book that includes the word paṇṇāsakaṃ should be excluded, eg "catutthapaṇṇāsakaṃ samattaṃ"
  - here's pattern to exclude, the vagga always ends with "tassuddānaṃ " (recitation of this) and a reciters verse. exclude that and whatever comes below it, normally 2-4 lines of verse

- Types:
  - Blacklisted line tag excluded
  - Line tag with blacklisted workd excluded
  - Child tags excluded (e.g. note)
  - Parts of line exlucded (e.g. /\(.*\)/, ...pe...)
  - Characters nuked
  - ToLowerCase

- Tests
  - For combinations of the above

- #TODO
  - For self test validate that line lengths are adding up
#>

BeforeAll {
  Import-Module .\PSExtractTexts.psm1 -Force

  function Get-XmlNodeFromString {
    param($String)

    Select-Xml -Xml ([xml]$String) -XPath "*"
  }

  function Test-Output {
    param(
      $OriginalText,
      $Node,
      $ExpectedIncludedText,
      $ExpectedExcludedText,
      [Parameter(ValueFromPipeline = $true)]
      $Output
    )

    Process {
      $Output[0] | Should -BeExactly $ExpectedIncludedText
      $Output[1] | Should -BeExactly $ExpectedExcludedText
      ($Output[0].Length + $Output[1].Length) | Should -BeExactly $Node.InnerText.Length
      $Node.OuterXml | Should -BeExactly $OriginalText
    }
  }
}

Describe "Get-TextFromNode" {
  Context "Main context" {
    It "Entire tag excluded e.g. centre" {
      $text = '<p rend="chapter">1. Mūlapariyāyavaggo</p>'
      $xml = Get-XmlNodeFromString -String $text

      $expectedIncluded = ""
      $expectedExcluded = "1. Mūlapariyāyavaggo"

      $xml.Node
      | Get-TextFromNode
      | Test-Output $text $xml.Node $expectedIncluded $expectedExcluded
    }

    It "Sub tags excluded rest in caps" {
      $text = '<p rend="bodytext" n="2"><hi rend="paranum">2</hi><hi rend="dot">.</hi> Hello World!</p>'
      $xml = Get-XmlNodeFromString -String $text

      $expectedIncluded = " hello world!"
      $expectedExcluded = "2."

      $xml.Node
      | Get-TextFromNode
      | Test-Output $text $xml.Node $expectedIncluded $expectedExcluded
    }

    It "Sub tags as well as special characters excluded" {
      $text = '<p rend="bodytext" n="2"><hi rend="paranum">2</hi><hi rend="dot">.</hi> Hello World!.a,1??2'‘3;4'’'’'’'’5–6-7…8</p>'
      $xml = Get-XmlNodeFromString -String $text

      $expectedIncluded = " hello world!a12345678"
      $expectedExcluded = "2..,??‘;’’’’–-…"

      $xml.Node
      | Get-TextFromNode
      | Test-Output $text $xml.Node $expectedIncluded $expectedExcluded
    }

    It "Sub tags excluded - 2: e.g. <note>" {
      $text = @"
<p rend="bodytext" n="2"><hi rend="paranum">2</hi><hi rend="dot">.</hi> ‘‘Idha, bhikkhave, assutavā puthujjano ariyānaṃ adassāvī ariyadhammassa akovido <pb ed="V" n="1.0002" /> ariyadhamme avinīto, sappurisānaṃ adassāvī sappurisadhammassa akovido sappurisadhamme avinīto – pathaviṃ <note>paṭhaviṃ (sī. syā. kaṃ. pī.)</note> pathavito sañjānāti; pathaviṃ pathavito saññatvā pathaviṃ maññati, pathaviyā maññati, pathavito maññati, pathaviṃ meti maññati <pb ed="T" n="1.0002" />, pathaviṃ abhinandati. Taṃ kissa hetu? ‘Apariññātaṃ tassā’ti vadāmi.</p>
"@
      $xml = Get-XmlNodeFromString -String $text

      $expectedIncluded = " idha bhikkhave assutavā puthujjano ariyānaṃ adassāvī ariyadhammassa akovido  ariyadhamme avinīto sappurisānaṃ adassāvī sappurisadhammassa akovido sappurisadhamme avinīto  pathaviṃ  pathavito sañjānāti pathaviṃ pathavito saññatvā pathaviṃ maññati pathaviyā maññati pathavito maññati pathaviṃ meti maññati  pathaviṃ abhinandati taṃ kissa hetu apariññātaṃ tassāti vadāmi"
      $expectedExcluded = @"
2.‘‘,,,–paṭhaviṃ (sī. syā. kaṃ. pī.);,,,,.?‘’.
"@

      $xml.Node
      | Get-TextFromNode
      | Test-Output $text $xml.Node $expectedIncluded $expectedExcluded
    }

    It "Sub tags excluded - nested case" {
      $text = '<p rend="bodytext" n="14"><hi rend="paranum">14</hi><hi rend="dot">.</hi><hi rend="bold">Aṭṭha <pb ed="V" n="0.0116" /> puggalā –</hi></p>'
      $xml = Get-XmlNodeFromString -String $text

      $expectedIncluded = "aṭṭha  puggalā "
      $expectedExcluded = "14.–"

      $xml.Node
      | Get-TextFromNode
      | Test-Output $text $xml.Node $expectedIncluded $expectedExcluded
    }

    It "Parts of line excluded - case insensetive e.g. ...pe..." {
      $text = '<p rend="bodytext">Sekkhavasena…Pe… dutiyanayabhūmiparicchedo niṭṭhito</p>'
      $xml = Get-XmlNodeFromString -String $text

      $expectedIncluded = "sekkhavasena dutiyanayabhūmiparicchedo niṭṭhito"
      $expectedExcluded = "…Pe…"

      $xml.Node
      | Get-TextFromNode
      | Test-Output $text $xml.Node $expectedIncluded $expectedExcluded
    }

    It "Characters removed e.g. .," {
      $text = '<p rend="bodytext">string1 .,?'‘ string2 ;'’–-… string3</p>'
      $xml = Get-XmlNodeFromString -String $text

      $expectedIncluded = "string1  string2  string3"
      $expectedExcluded = ".,?‘;’–-…"

      $xml.Node
      | Get-TextFromNode
      | Test-Output $text $xml.Node $expectedIncluded $expectedExcluded
    }

    It "Lines with nested node excluded e.g. note within hi.bold" {
      $text = @"
<p rend="gathalast">x y z; <hi rend="bold">Yato puññena te senti <note>sentu (ka.)</note>, jenapādambujadvaye</hi> x.</p>
"@
      $xml = Get-XmlNodeFromString -String $text

      $expectedIncluded = "x y z yato puññena te senti  jenapādambujadvaye x"
      $expectedExcluded = ";sentu (ka.),."

      $xml.Node
      | Get-TextFromNode
      | Test-Output $text $xml.Node $expectedIncluded $expectedExcluded
    }

#     It "Lines with blacklisted words removed e.g. paṇṇāsakaṃ" {
#       $text = @"
# <p rend="bodytext"><hi rend="bold">Vissajjanā –</hi> tīsu bhante paṇṇāsakesu mūlapaṇṇāsakaṃ nāma pāvacanaṃ dhammasaṃgāhakā mahātheravarā paṭhamaṃ saṃgāyiṃsu.</p>
# "@
#       $xml = Get-XmlNodeFromString -String $text

#       $expectedIncluded = ""
#       $expectedExcluded = "Vissajjanā – tīsu bhante paṇṇāsakesu mūlapaṇṇāsakaṃ nāma pāvacanaṃ dhammasaṃgāhakā mahātheravarā paṭhamaṃ saṃgāyiṃsu."

#       $xml.Node
#       | Get-TextFromNode
#       | Test-Output $text $xml.Node $expectedIncluded $expectedExcluded
#     }
  }
}
