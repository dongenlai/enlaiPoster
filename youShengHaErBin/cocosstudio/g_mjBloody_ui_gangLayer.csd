<GameFile>
  <PropertyGroup Name="g_mjBloody_ui_gangLayer" Type="Layer" ID="f4904989-3abf-472a-8997-064b9ad25b38" Version="2.3.3.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="0" Speed="1.0000" />
      <ObjectData Name="Layer" Tag="357" ctype="GameLayerObjectData">
        <Size X="1334.0000" Y="750.0000" />
        <Children>
          <AbstractNodeData Name="_bg" CanEdit="False" ActionTag="50685484" Tag="358" IconVisible="False" HorizontalEdge="BothEdge" VerticalEdge="TopEdge" LeftMargin="267.0000" RightMargin="267.0000" TopMargin="300.0000" BottomMargin="176.0000" Scale9Enable="True" LeftEage="203" RightEage="203" TopEage="90" BottomEage="90" Scale9OriginX="203" Scale9OriginY="90" Scale9Width="210" Scale9Height="94" ctype="ImageViewObjectData">
            <Size X="800.0000" Y="274.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="667.0000" Y="313.0000" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.5000" Y="0.4173" />
            <PreSize X="0.5997" Y="0.3653" />
            <FileData Type="Normal" Path="hallUi/i/6.png" Plist="" />
          </AbstractNodeData>
          <AbstractNodeData Name="_selectBtn" ActionTag="777992550" CallBackType="Click" CallBackName="onSelect" Tag="360" IconVisible="False" HorizontalEdge="BothEdge" VerticalEdge="BottomEdge" LeftMargin="586.4457" RightMargin="603.5543" TopMargin="494.8612" BottomMargin="182.1388" TouchEnable="True" FontSize="14" LeftEage="15" RightEage="15" TopEage="11" BottomEage="11" Scale9OriginX="15" Scale9OriginY="11" Scale9Width="114" Scale9Height="51" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="ButtonObjectData">
            <Size X="144.0000" Y="73.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="658.4457" Y="218.6388" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.4936" Y="0.2915" />
            <PreSize X="0.1079" Y="0.0973" />
            <TextColor A="255" R="65" G="65" B="70" />
            <DisabledFileData Type="Normal" Path="g/mjBloody/ui/Notice_okBtn.png" Plist="" />
            <PressedFileData Type="Normal" Path="g/mjBloody/ui/Notice_okBtn.png" Plist="" />
            <NormalFileData Type="Normal" Path="g/mjBloody/ui/Notice_okBtn.png" Plist="" />
            <OutlineColor A="255" R="255" G="0" B="0" />
            <ShadowColor A="255" R="110" G="110" B="110" />
          </AbstractNodeData>
          <AbstractNodeData Name="_tipBg" ActionTag="-1168803086" VisibleForFrame="False" Tag="214" IconVisible="False" LeftMargin="310.8815" RightMargin="293.1184" TopMargin="268.2420" BottomMargin="144.7580" ctype="SpriteObjectData">
            <Size X="730.0000" Y="337.0000" />
            <Children>
              <AbstractNodeData Name="Text_1" ActionTag="-966207757" Tag="215" IconVisible="False" LeftMargin="115.7063" RightMargin="86.2937" TopMargin="86.8722" BottomMargin="194.1278" FontSize="50" LabelText="是否继续选择其它杠牌？" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="TextObjectData">
                <Size X="528.0000" Y="56.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="379.7063" Y="222.1278" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="26" G="26" B="26" />
                <PrePosition X="0.5201" Y="0.6591" />
                <PreSize X="0.7233" Y="0.1662" />
                <FontResource Type="Normal" Path="hallUi/common/front.TTF" Plist="" />
                <OutlineColor A="255" R="255" G="0" B="0" />
                <ShadowColor A="255" R="110" G="110" B="110" />
              </AbstractNodeData>
              <AbstractNodeData Name="Button_2" ActionTag="-1716299549" CallBackType="Click" CallBackName="onCancel" Tag="216" IconVisible="False" LeftMargin="102.2369" RightMargin="410.7631" TopMargin="219.8633" BottomMargin="46.1367" TouchEnable="True" FontSize="14" LeftEage="15" RightEage="15" TopEage="11" BottomEage="11" Scale9OriginX="15" Scale9OriginY="11" Scale9Width="187" Scale9Height="49" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="ButtonObjectData">
                <Size X="217.0000" Y="71.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="210.7369" Y="81.6367" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition X="0.2887" Y="0.2422" />
                <PreSize X="0.2973" Y="0.2107" />
                <TextColor A="255" R="65" G="65" B="70" />
                <DisabledFileData Type="Normal" Path="g/mjBloody/ui/ui_quit4.png" Plist="" />
                <PressedFileData Type="Normal" Path="g/mjBloody/ui/ui_quit4.png" Plist="" />
                <NormalFileData Type="Normal" Path="g/mjBloody/ui/ui_quit4.png" Plist="" />
                <OutlineColor A="255" R="255" G="0" B="0" />
                <ShadowColor A="255" R="110" G="110" B="110" />
              </AbstractNodeData>
              <AbstractNodeData Name="Button_3" ActionTag="-1779945350" CallBackType="Click" CallBackName="onSure" Tag="217" IconVisible="False" LeftMargin="415.8938" RightMargin="94.1062" TopMargin="219.8633" BottomMargin="44.1367" TouchEnable="True" FontSize="14" LeftEage="15" RightEage="15" TopEage="11" BottomEage="11" Scale9OriginX="15" Scale9OriginY="11" Scale9Width="190" Scale9Height="51" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="ButtonObjectData">
                <Size X="220.0000" Y="73.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="525.8938" Y="80.6367" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition X="0.7204" Y="0.2393" />
                <PreSize X="0.3014" Y="0.2166" />
                <TextColor A="255" R="65" G="65" B="70" />
                <DisabledFileData Type="Normal" Path="g/mjBloody/ui/ui_quit5.png" Plist="" />
                <PressedFileData Type="Normal" Path="g/mjBloody/ui/ui_quit5.png" Plist="" />
                <NormalFileData Type="Normal" Path="g/mjBloody/ui/ui_quit5.png" Plist="" />
                <OutlineColor A="255" R="255" G="0" B="0" />
                <ShadowColor A="255" R="110" G="110" B="110" />
              </AbstractNodeData>
            </Children>
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="675.8815" Y="313.2580" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.5067" Y="0.4177" />
            <PreSize X="0.5472" Y="0.4493" />
            <FileData Type="Normal" Path="g/mjBloody/ui/ui_quit2.png" Plist="" />
            <BlendFunc Src="770" Dst="771" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>