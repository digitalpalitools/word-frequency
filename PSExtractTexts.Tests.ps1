BeforeAll {
  Import-Module .\PSExtractTexts.psm1 -Force

  function Get-XmlNodeFromString {
    param($String)

    Select-Xml -Xml ([xml]$String) -XPath "*"
  }
}

<#
- TODO:
  - "-"" in the exclusion character class
  - \(.*\) in the exclusion character class
  - here's pattern to exclude, the vagga always ends with "tassuddānaṃ " (recitation of this) and a reciters verse. exclude that and whatever comes below it, normally 2-4 lines of verse
  - [TODO] any line in any book that includes the word paṇṇāsakaṃ should be excluded, eg "catutthapaṇṇāsakaṃ samattaṃ"
  - the brackets and everything in them can be excluded - exclude () and everything in them just for this file or all across?
  - everything marked with <hi rend="bold"> should be included
  - note within hi-bold <p rend="gatha1"><hi rend="bold">‘‘Dhīre</hi><pb ed="P" n="0.0124" /><hi rend="bold"> nirodhaṃ phusehi <note>phussehi (sī.)</note>, saññāvūpasamaṃ sukhaṃ;</hi></p>

- Types:
  - Blacklisted line tag excluded
  - Line tag with blacklisted workd excluded
  - Child tags excluded (e.g. note)
  - Parts of line exlucded (e.g. /\(.*\)/, ...pe...)
  - Characters nuked
  - ToLowerCase

- Tests
  - For combinations of the above
#>

Describe "Get-TextFromNode" {
  Context "Main context" {
    It "Entire tag excluded e.g. centre" {
      $text = '<p rend="chapter">1. Mūlapariyāyavaggo</p>'
      $xml = Get-XmlNodeFromString -String $text

      $ret = $xml.Node | Get-TextFromNode
      $ret | Should -BeExactly @("", "1. Mūlapariyāyavaggo")
      $ret[0].Length + $ret[1].Length | Should -BeExactly $xml.Node.InnerText.Length
      $xml.Node.OuterXml | Should -BeExactly $text
    }

    It "Sub tags excluded rest in caps" {
      $text = '<p rend="bodytext" n="2"><hi rend="paranum">2</hi><hi rend="dot">.</hi> Hello World!</p>'
      $xml = Get-XmlNodeFromString -String $text

      $ret = $xml.Node | Get-TextFromNode
      $ret | Should -BeExactly @(" hello world!", "2.")
      $ret[0].Length + $ret[1].Length | Should -BeExactly $xml.Node.InnerText.Length
      $xml.Node.OuterXml | Should -BeExactly $text
    }

    It "Sub tags as well as special characters excluded" {
      $text = '<p rend="bodytext" n="2"><hi rend="paranum">2</hi><hi rend="dot">.</hi> Hello World!.a,1??2'‘3;4'’'’'’'’5–6-7…8</p>'
      $xml = Get-XmlNodeFromString -String $text

      $ret = $xml.Node | Get-TextFromNode
      $ret | Should -BeExactly @(" hello world!a123456-78", "2..,??‘;’’’’–…")
      $ret[0].Length + $ret[1].Length | Should -BeExactly $xml.Node.InnerText.Length
      $xml.Node.OuterXml | Should -BeExactly $text
    }

    It "Sub tags excluded - 2: e.g. <note>" {
      $text = @"
<p rend="bodytext" n="2"><hi rend="paranum">2</hi><hi rend="dot">.</hi> ‘‘Idha, bhikkhave, assutavā puthujjano ariyānaṃ adassāvī ariyadhammassa akovido <pb ed="V" n="1.0002" /> ariyadhamme avinīto, sappurisānaṃ adassāvī sappurisadhammassa akovido sappurisadhamme avinīto – pathaviṃ <note>paṭhaviṃ (sī. syā. kaṃ. pī.)</note> pathavito sañjānāti; pathaviṃ pathavito saññatvā pathaviṃ maññati, pathaviyā maññati, pathavito maññati, pathaviṃ meti maññati <pb ed="T" n="1.0002" />, pathaviṃ abhinandati. Taṃ kissa hetu? ‘Apariññātaṃ tassā’ti vadāmi.</p>
"@
      $xml = Get-XmlNodeFromString -String $text

      $ret = $xml.Node | Get-TextFromNode
      $ret[0] | Should -BeExactly " idha bhikkhave assutavā puthujjano ariyānaṃ adassāvī ariyadhammassa akovido  ariyadhamme avinīto sappurisānaṃ adassāvī sappurisadhammassa akovido sappurisadhamme avinīto  pathaviṃ  pathavito sañjānāti pathaviṃ pathavito saññatvā pathaviṃ maññati pathaviyā maññati pathavito maññati pathaviṃ meti maññati  pathaviṃ abhinandati taṃ kissa hetu apariññātaṃ tassāti vadāmi"
      $ret[1] | Should -BeExactly @"
2.‘‘,,,–paṭhaviṃ (sī. syā. kaṃ. pī.);,,,,.?‘’.
"@
      $ret[0].Length + $ret[1].Length | Should -BeExactly $xml.Node.InnerText.Length
      $xml.Node.OuterXml | Should -BeExactly $text
    }

    It "Sub tags excluded - nested case" {
      $text = '<p rend="bodytext" n="14"><hi rend="paranum">14</hi><hi rend="dot">.</hi><hi rend="bold">Aṭṭha <pb ed="V" n="0.0116" /> puggalā –</hi></p>'
      $xml = Get-XmlNodeFromString -String $text

      $ret = $xml.Node | Get-TextFromNode
      $ret[0] | Should -BeExactly ""
      $ret[1] | Should -BeExactly @"
14.Aṭṭha  puggalā –
"@
      $ret[0].Length + $ret[1].Length | Should -BeExactly $xml.Node.InnerText.Length
      $xml.Node.OuterXml | Should -BeExactly $text
    }

    It "Parts of line excluded e.g. ...pe..." {
      $text = '<p rend="bodytext">Sekkhavasena…pe… dutiyanayabhūmiparicchedo niṭṭhito</p>'
      $xml = Get-XmlNodeFromString -String $text

      $ret = $xml.Node | Get-TextFromNode
      $ret[0] | Should -BeExactly "sekkhavasena dutiyanayabhūmiparicchedo niṭṭhito"
      $ret[1] | Should -BeExactly "…pe…"
      $ret[0].Length + $ret[1].Length | Should -BeExactly $xml.Node.InnerText.Length
      $xml.Node.OuterXml | Should -BeExactly $text
    }

    It "Characters removed e.g. .," {
      $text = '<p rend="bodytext">string1 .,?'‘ string2 ;'’–-… string3</p>'
      $xml = Get-XmlNodeFromString -String $text

      $ret = $xml.Node | Get-TextFromNode
      $ret[0] | Should -BeExactly "string1  string2 - string3"
      $ret[1] | Should -BeExactly ".,?‘;’–…"
      $ret[0].Length + $ret[1].Length | Should -BeExactly $xml.Node.InnerText.Length
      $xml.Node.OuterXml | Should -BeExactly $text
    }
  }
}
