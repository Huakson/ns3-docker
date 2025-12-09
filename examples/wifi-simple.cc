/**
 * @file wifi-simple.cc
 * @brief Simple Wi-Fi simulation example for NS-3 Docker
 *
 * This example creates a basic Wi-Fi network with 2 nodes and measures
 * packet delivery ratio, throughput, and delay.
 */

#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/internet-module.h"
#include "ns3/applications-module.h"
#include "ns3/wifi-module.h"
#include "ns3/mobility-module.h"
#include "ns3/flow-monitor-module.h"

#include <iostream>
#include <fstream>

using namespace ns3;

NS_LOG_COMPONENT_DEFINE("WifiSimpleExample");

int main(int argc, char *argv[])
{
    // Simulation parameters
    uint32_t nNodes = 2;
    double distance = 50.0; // meters
    double simulationTime = 10.0; // seconds
    bool verbose = false;

    // Command line arguments
    CommandLine cmd(__FILE__);
    cmd.AddValue("nNodes", "Number of nodes", nNodes);
    cmd.AddValue("distance", "Distance between nodes (m)", distance);
    cmd.AddValue("time", "Simulation time (s)", simulationTime);
    cmd.AddValue("verbose", "Enable verbose logging", verbose);
    cmd.Parse(argc, argv);

    if (verbose)
    {
        LogComponentEnable("WifiSimpleExample", LOG_LEVEL_INFO);
    }

    Time::SetResolution(Time::NS);

    // Create nodes
    NodeContainer nodes;
    nodes.Create(nNodes);

    // Configure Wi-Fi
    WifiHelper wifi;
    wifi.SetStandard(WIFI_STANDARD_80211n);

    YansWifiPhyHelper wifiPhy;
    YansWifiChannelHelper wifiChannel;
    wifiChannel.SetPropagationDelay("ns3::ConstantSpeedPropagationDelayModel");
    wifiChannel.AddPropagationLoss("ns3::FriisPropagationLossModel");
    wifiPhy.SetChannel(wifiChannel.Create());

    WifiMacHelper wifiMac;
    wifiMac.SetType("ns3::AdhocWifiMac");

    NetDeviceContainer devices = wifi.Install(wifiPhy, wifiMac, nodes);

    // Configure mobility
    MobilityHelper mobility;
    Ptr<ListPositionAllocator> positionAlloc = CreateObject<ListPositionAllocator>();
    positionAlloc->Add(Vector(0.0, 0.0, 0.0));
    positionAlloc->Add(Vector(distance, 0.0, 0.0));
    mobility.SetPositionAllocator(positionAlloc);
    mobility.SetMobilityModel("ns3::ConstantPositionMobilityModel");
    mobility.Install(nodes);

    // Install Internet stack
    InternetStackHelper internet;
    internet.Install(nodes);

    Ipv4AddressHelper ipv4;
    ipv4.SetBase("10.1.1.0", "255.255.255.0");
    Ipv4InterfaceContainer interfaces = ipv4.Assign(devices);

    // Configure applications
    uint16_t port = 9;

    // Server
    UdpServerHelper server(port);
    ApplicationContainer serverApps = server.Install(nodes.Get(1));
    serverApps.Start(Seconds(0.0));
    serverApps.Stop(Seconds(simulationTime));

    // Client
    UdpClientHelper client(interfaces.GetAddress(1), port);
    client.SetAttribute("MaxPackets", UintegerValue(10000));
    client.SetAttribute("Interval", TimeValue(Seconds(0.001)));
    client.SetAttribute("PacketSize", UintegerValue(1024));

    ApplicationContainer clientApps = client.Install(nodes.Get(0));
    clientApps.Start(Seconds(1.0));
    clientApps.Stop(Seconds(simulationTime));

    // Flow Monitor
    FlowMonitorHelper flowmon;
    Ptr<FlowMonitor> monitor = flowmon.InstallAll();

    // Run simulation
    Simulator::Stop(Seconds(simulationTime + 1.0));
    Simulator::Run();

    // Calculate metrics
    monitor->CheckForLostPackets();
    Ptr<Ipv4FlowClassifier> classifier = DynamicCast<Ipv4FlowClassifier>(flowmon.GetClassifier());
    FlowMonitor::FlowStatsContainer stats = monitor->GetFlowStats();

    std::cout << "\n========================================\n";
    std::cout << "  Wi-Fi Simple Simulation Results\n";
    std::cout << "========================================\n";
    std::cout << "Distance: " << distance << " m\n";
    std::cout << "Simulation Time: " << simulationTime << " s\n";
    std::cout << "----------------------------------------\n";

    for (auto const& [flowId, flowStats] : stats)
    {
        Ipv4FlowClassifier::FiveTuple t = classifier->FindFlow(flowId);

        double txPackets = flowStats.txPackets;
        double rxPackets = flowStats.rxPackets;
        double lostPackets = flowStats.lostPackets;
        double pdr = (rxPackets / txPackets) * 100.0;
        double throughput = (flowStats.rxBytes * 8.0) / (simulationTime - 1.0) / 1000.0; // kbps
        double delay = flowStats.delaySum.GetMilliSeconds() / rxPackets;

        std::cout << "Flow " << flowId << " (" << t.sourceAddress << " -> " << t.destinationAddress << ")\n";
        std::cout << "  Tx Packets: " << txPackets << "\n";
        std::cout << "  Rx Packets: " << rxPackets << "\n";
        std::cout << "  Lost Packets: " << lostPackets << "\n";
        std::cout << "  PDR: " << pdr << " %\n";
        std::cout << "  Throughput: " << throughput << " kbps\n";
        std::cout << "  Average Delay: " << delay << " ms\n";
    }

    std::cout << "========================================\n\n";

    // Save to CSV
    std::ofstream csvFile("/ns3/results/wifi-simple-results.csv", std::ios::app);
    if (csvFile.is_open())
    {
        // Write header if file is empty
        csvFile.seekp(0, std::ios::end);
        if (csvFile.tellp() == 0)
        {
            csvFile << "Distance,TxPackets,RxPackets,PDR,Throughput_kbps,Delay_ms\n";
        }

        for (auto const& [flowId, flowStats] : stats)
        {
            double pdr = (flowStats.rxPackets / (double)flowStats.txPackets) * 100.0;
            double throughput = (flowStats.rxBytes * 8.0) / (simulationTime - 1.0) / 1000.0;
            double delay = flowStats.delaySum.GetMilliSeconds() / flowStats.rxPackets;

            csvFile << distance << ","
                    << flowStats.txPackets << ","
                    << flowStats.rxPackets << ","
                    << pdr << ","
                    << throughput << ","
                    << delay << "\n";
        }
        csvFile.close();
    }

    Simulator::Destroy();
    return 0;
}
