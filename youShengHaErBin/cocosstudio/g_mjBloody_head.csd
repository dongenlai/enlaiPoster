<GameFile>
  <PropertyGroup Name="g_mjBloody_head" Type="Layer" ID="ca095ec9-00b4-4b5b-af6f-c6123815cce7" Version="2.3.3.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="30" Speed="1.0000" ActivedAnimationName="animation0">
        <Timeline ActionTag="1105874500" Property="Position">
          <PointFrame FrameIndex="0" X="121.2095" Y="146.1575">
            <EasingData Type="0" />
          </PointFrame>
          <PointFrame FrameIndex="30" X="121.2100" Y="146.1600">
            <EasingData Type="16" />
          </PointFrame>
        </Timeline>
        <Timeline ActionTag="1105874500" Property="Scale">
          <ScaleFrame FrameIndex="0" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="30" X="1.0000" Y="1.0000">
            <EasingData Type="16" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="1105874500" Property="RotationSkew">
          <ScaleFrame FrameIndex="0" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="30" X="0.0000" Y="0.0000">
            <EasingData Type="16" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="1105874500" Property="Alpha">
          <IntFrame FrameIndex="0" Value="255">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="30" Value="0">
            <EasingData Type="16" />
          </IntFrame>
        </Timeline>
        <Timeline ActionTag="-774438364" Property="Position">
          <PointFrame FrameIndex="0" X="121.6500" Y="150.3600">
            <EasingData Type="0" />
          </PointFrame>
          <PointFrame FrameIndex="10" X="121.6500" Y="150.3600">
            <EasingData Type="0" />
          </PointFrame>
          <PointFrame FrameIndex="20" X="121.6500" Y="150.3600">
            <EasingData Type="0" />
          </PointFrame>
        </Timeline>
        <Timeline ActionTag="-774438364" Property="Scale">
          <ScaleFrame FrameIndex="0" X="2.0000" Y="2.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="10" X="0.7000" Y="0.7000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="20" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="-774438364" Property="RotationSkew">
          <ScaleFrame FrameIndex="0" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="10" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="20" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
      </Animation>
      <AnimationList>
        <AnimationInfo Name="animation0" StartIndex="0" EndIndex="30">
          <RenderColor A="255" R="255" G="248" B="220" />
        </AnimationInfo>
      </AnimationList>
      <ObjectData Name="Layer" Tag="7" ctype="GameLayerObjectData">
        <Size X="120.0000" Y="150.0000" />
        <Children>
          <AbstractNodeData Name="_headWait" ActionTag="-516979510" VisibleForFrame="False" Tag="369" IconVisible="False" LeftMargin="-59.7164" RightMargin="-52.2836" TopMargin="-42.2130" BottomMargin="-79.7870" ctype="SpriteObjectData">
            <Size X="232.0000" Y="272.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="56.2836" Y="56.2130" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.4690" Y="0.3748" />
            <PreSize X="1.9333" Y="1.8133" />
            <FileData Type="Normal" Path="g/mjBloody/ani/headai_1_03.png" Plist="" />
            <BlendFunc Src="770" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="Panel_1" ActionTag="124751416" CallBackType="Touch" CallBackName="onHeadTouch" Tag="12" IconVisible="False" LeftMargin="1.5843" RightMargin="-1.5843" TopMargin="1.5846" BottomMargin="-1.5846" TouchEnable="True" BackColorAlpha="141" ComboBoxIndex="1" ColorAngle="90.0000" Scale9Width="1" Scale9Height="1" ctype="PanelObjectData">
            <Size X="120.0000" Y="150.0000" />
            <Children>
              <AbstractNodeData Name="_beanNum" ActionTag="-1521631963" Tag="20" IconVisible="False" LeftMargin="52.1328" RightMargin="52.8672" TopMargin="124.0736" BottomMargin="4.9264" CharWidth="15" CharHeight="21" LabelText="0" StartChar="/" ctype="TextAtlasObjectData">
                <Size X="15.0000" Y="21.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="59.6328" Y="15.4264" />
                <Scale ScaleX="1.5000" ScaleY="1.5000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition X="0.4969" Y="0.1028" />
                <PreSize X="0.1250" Y="0.1400" />
                <LabelAtlasFileImage_CNB Type="Normal" Path="g/mjBloody/ui/changci_peoplenum.png" Plist="" />
              </AbstractNodeData>
              <AbstractNodeData Name="_imgHead" ActionTag="131494181" Tag="133" IconVisible="False" LeftMargin="9.0000" RightMargin="7.0000" TopMargin="7.0000" BottomMargin="31.0000" ctype="SpriteObjectData">
                <Size X="104.0000" Y="112.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="61.0000" Y="87.0000" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition X="0.5083" Y="0.5800" />
                <PreSize X="0.8667" Y="0.7467" />
                <FileData Type="Normal" Path="g/mjBloody/ui/head.png" Plist="" />
                <BlendFunc Src="770" Dst="771" />
              </AbstractNodeData>
            </Children>
            <AnchorPoint />
            <Position X="1.5843" Y="-1.5846" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.0132" Y="-0.0106" />
            <PreSize X="1.0000" Y="1.0000" />
            <SingleColor A="255" R="0" G="0" B="0" />
            <FirstColor A="255" R="150" G="200" B="255" />
            <EndColor A="255" R="255" G="255" B="255" />
            <ColorVector ScaleY="1.0000" />
          </AbstractNodeData>
          <AbstractNodeData Name="_tingState" ActionTag="-4233507" VisibleForFrame="False" Tag="1108" IconVisible="False" LeftMargin="107.2227" RightMargin="-35.2227" TopMargin="35.1133" BottomMargin="28.8867" Scale9Width="48" Scale9Height="86" ctype="ImageViewObjectData">
            <Size X="48.0000" Y="86.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="131.2227" Y="71.8867" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="1.0935" Y="0.4792" />
            <PreSize X="0.4000" Y="0.5733" />
            <FileData Type="Normal" Path="g/mjBloody/ui/t.png" Plist="" />
          </AbstractNodeData>
          <AbstractNodeData Name="_imgLight" ActionTag="1105874500" VisibleForFrame="False" Tag="26" IconVisible="False" LeftMargin="75.2095" RightMargin="-47.2095" TopMargin="-42.1575" BottomMargin="100.1575" ctype="SpriteObjectData">
            <Size X="92.0000" Y="92.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="121.2095" Y="146.1575" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="1.0101" Y="0.9744" />
            <PreSize X="0.7667" Y="0.6133" />
            <FileData Type="Normal" Path="g/mjBloody/ui/PlayerState_guangquan_1.png" Plist="" />
            <BlendFunc Src="1" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="_imgState" ActionTag="-774438364" VisibleForFrame="False" Tag="133" IconVisible="False" LeftMargin="107.1500" RightMargin="-16.1500" TopMargin="-14.8600" BottomMargin="135.8600" Scale9Width="29" Scale9Height="29" ctype="ImageViewObjectData">
            <Size X="29.0000" Y="29.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="121.6500" Y="150.3600" />
            <Scale ScaleX="2.0000" ScaleY="2.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="1.0137" Y="1.0024" />
            <PreSize X="0.2417" Y="0.1933" />
            <FileData Type="Normal" Path="g/mjBloody/ui/PlayerState_que0.png" Plist="" />
          </AbstractNodeData>
          <AbstractNodeData Name="_txtName" ActionTag="-297413693" Tag="147" IconVisible="False" LeftMargin="33.3614" RightMargin="35.6386" TopMargin="-26.3517" BottomMargin="149.3517" FontSize="24" LabelText="名称" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="TextObjectData">
            <Size X="51.0000" Y="27.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="58.8614" Y="162.8517" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="227" G="183" B="93" />
            <PrePosition X="0.4905" Y="1.0857" />
            <PreSize X="0.4250" Y="0.1800" />
            <FontResource Type="Normal" Path="hallUi/common/front.TTF" Plist="" />
            <OutlineColor A="255" R="255" G="0" B="0" />
            <ShadowColor A="255" R="110" G="110" B="110" />
          </AbstractNodeData>
          <AbstractNodeData Name="_userInfoCon" ActionTag="829522579" VisibleForFrame="False" Tag="644" IconVisible="False" LeftMargin="118.8138" RightMargin="-354.8138" TopMargin="-2.4625" BottomMargin="-4.5375" Scale9Enable="True" LeftEage="30" RightEage="30" TopEage="30" BottomEage="30" Scale9OriginX="30" Scale9OriginY="30" Scale9Width="19" Scale9Height="97" ctype="ImageViewObjectData">
            <Size X="356.0000" Y="157.0000" />
            <Children>
              <AbstractNodeData Name="Text_10" ActionTag="440661362" Tag="762" IconVisible="False" LeftMargin="27.9997" RightMargin="291.0003" TopMargin="34.5891" BottomMargin="84.4109" FontSize="34" LabelText="ID:" ShadowOffsetX="0.0000" ShadowOffsetY="0.0000" ShadowEnabled="True" ctype="TextObjectData">
                <Size X="37.0000" Y="38.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="46.4997" Y="103.4109" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="126" G="104" B="59" />
                <PrePosition X="0.1306" Y="0.6587" />
                <PreSize X="0.1039" Y="0.2420" />
                <FontResource Type="Normal" Path="hallUi/common/front.TTF" Plist="" />
                <OutlineColor A="255" R="255" G="0" B="0" />
                <ShadowColor A="255" R="126" G="104" B="59" />
              </AbstractNodeData>
              <AbstractNodeData Name="Text_10_0" ActionTag="-1928578123" Tag="763" IconVisible="False" LeftMargin="29.3103" RightMargin="293.6897" TopMargin="80.0390" BottomMargin="38.9610" FontSize="34" LabelText="IP:" ShadowOffsetX="0.0000" ShadowOffsetY="0.0000" ShadowEnabled="True" ctype="TextObjectData">
                <Size X="33.0000" Y="38.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="45.8103" Y="57.9610" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="126" G="104" B="59" />
                <PrePosition X="0.1287" Y="0.3692" />
                <PreSize X="0.0927" Y="0.2420" />
                <FontResource Type="Normal" Path="hallUi/common/front.TTF" Plist="" />
                <OutlineColor A="255" R="255" G="0" B="0" />
                <ShadowColor A="255" R="126" G="104" B="59" />
              </AbstractNodeData>
              <AbstractNodeData Name="_userId" ActionTag="-984750173" Tag="764" IconVisible="False" LeftMargin="72.4975" RightMargin="211.5025" TopMargin="36.5010" BottomMargin="82.4990" FontSize="34" LabelText="111111" ShadowOffsetX="0.0000" ShadowOffsetY="0.0000" ShadowEnabled="True" ctype="TextObjectData">
                <Size X="72.0000" Y="38.0000" />
                <AnchorPoint ScaleY="0.5000" />
                <Position X="72.4975" Y="101.4990" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="126" G="104" B="59" />
                <PrePosition X="0.2036" Y="0.6465" />
                <PreSize X="0.2022" Y="0.2420" />
                <FontResource Type="Normal" Path="hallUi/common/front.TTF" Plist="" />
                <OutlineColor A="255" R="255" G="0" B="0" />
                <ShadowColor A="255" R="126" G="104" B="59" />
              </AbstractNodeData>
              <AbstractNodeData Name="_userIp" ActionTag="146911424" Tag="765" IconVisible="False" LeftMargin="73.4984" RightMargin="37.5016" TopMargin="79.5000" BottomMargin="39.5000" FontSize="34" LabelText="255.255.255.255" ShadowOffsetX="0.0000" ShadowOffsetY="0.0000" ShadowEnabled="True" ctype="TextObjectData">
                <Size X="245.0000" Y="38.0000" />
                <AnchorPoint ScaleY="0.5000" />
                <Position X="73.4984" Y="58.5000" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="126" G="104" B="59" />
                <PrePosition X="0.2065" Y="0.3726" />
                <PreSize X="0.6882" Y="0.2420" />
                <FontResource Type="Normal" Path="hallUi/common/front.TTF" Plist="" />
                <OutlineColor A="255" R="255" G="0" B="0" />
                <ShadowColor A="255" R="126" G="104" B="59" />
              </AbstractNodeData>
            </Children>
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="296.8138" Y="73.9625" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="2.4734" Y="0.4931" />
            <PreSize X="2.9667" Y="1.0467" />
            <FileData Type="Normal" Path="g/mjBloody/ui/ui_hutishi1.png" Plist="" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>