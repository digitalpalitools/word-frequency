BeforeAll {
  Import-Module .\PSExtractTexts.psm1 -Force

  function Get-XmlNodeFromString {
    param($String)

    Select-Xml -Xml ([xml]$String) -XPath "*"
  }
}

<#
- TODO:
  - \- in the exclusion character class
  - () in the exclusion character class

- Types:
  - Full tag excluded
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

      $xml.Node | Get-TextFromNode -ForInclusion | Should -Be ""
      $xml.Node.OuterXml | Should -Be $text
      $xml.Node | Get-TextFromNode | Should -Be "1. Mūlapariyāyavaggo"
      $xml.Node.OuterXml | Should -Be $text
    }

    It "Sub tags excluded e.g. <note>" {
      $text = '<p rend="bodytext" n="2"><hi rend="paranum">2</hi><hi rend="dot">.</hi> ‘‘Idha, bhikkhave, assutavā puthujjano ariyānaṃ adassāvī ariyadhammassa akovido <pb ed="V" n="1.0002" /> ariyadhamme avinīto, sappurisānaṃ adassāvī sappurisadhammassa akovido sappurisadhamme avinīto – pathaviṃ <note>paṭhaviṃ (sī. syā. kaṃ. pī.)</note> pathavito sañjānāti; pathaviṃ pathavito saññatvā pathaviṃ maññati, pathaviyā maññati, pathavito maññati, pathaviṃ meti maññati <pb ed="T" n="1.0002" />, pathaviṃ abhinandati. Taṃ kissa hetu? '‘Apariññātaṃ tassā'’ti vadāmi.</p>'
      $xml = Get-XmlNodeFromString -String $text

      $xml.Node | Get-TextFromNode -ForInclusion | Should -Be " idha bhikkhave assutavā puthujjano ariyānaṃ adassāvī ariyadhammassa akovido  ariyadhamme avinīto sappurisānaṃ adassāvī sappurisadhammassa akovido sappurisadhamme avinīto  pathaviṃ  pathavito sañjānāti pathaviṃ pathavito saññatvā pathaviṃ maññati pathaviyā maññati pathavito maññati pathaviṃ meti maññati  pathaviṃ abhinandati taṃ kissa hetu apariññātaṃ tassāti vadāmi"
      $xml.Node.OuterXml | Should -Be $text
      $xml.Node | Get-TextFromNode | Should -Be "2 .  paṭhaviṃ (sī. syā. kaṃ. pī.) "
      $xml.Node.OuterXml | Should -Be $text
    }

    It "Sub tags excluded - nested case" {
      $text = '<p rend="bodytext" n="14"><hi rend="paranum">14</hi><hi rend="dot">.</hi><hi rend="bold">Aṭṭha <pb ed="V" n="0.0116" /> puggalā –</hi></p>'
      $xml = Get-XmlNodeFromString -String $text

      $xml.Node | Get-TextFromNode -ForInclusion | Should -Be ""
      $xml.Node.OuterXml | Should -Be $text
      $xml.Node | Get-TextFromNode | Should -Be "14 . Aṭṭha  puggalā –"
      $xml.Node.OuterXml | Should -Be $text
    }

    It "Parts of line excluded e.g. ...pe..." {
      $text = '<p rend="bodytext">Sekkhavasena…pe… dutiyanayabhūmiparicchedo niṭṭhito.</p>'
      $xml = Get-XmlNodeFromString -String $text

      $xml.Node | Get-TextFromNode -ForInclusion | Should -Be "sekkhavasena dutiyanayabhūmiparicchedo niṭṭhito"
      $xml.Node.OuterXml | Should -Be $text
      # TODO: Complete this implementation
      $xml.Node | Get-TextFromNode | Should -Be ""
      $xml.Node.OuterXml | Should -Be $text
    }

    It "Characters removed e.g. .," {
      $text = '<p rend="bodytext">string1 .,?'‘ string2 ;'’–-… string3</p>'
      $xml = Get-XmlNodeFromString -String $text

      $xml.Node | Get-TextFromNode -ForInclusion | Should -Be "string1  string2 - string3"
      $xml.Node.OuterXml | Should -Be $text
      # TODO: Complete this implementation
      $xml.Node | Get-TextFromNode | Should -Be ""
      $xml.Node.OuterXml | Should -Be $text
    }
  }
}
