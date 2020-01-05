//
//  ContentView.swift
//  Boring Tasks
//
//  Created by Murat Corlu on 02/01/2020.
//  Copyright © 2020 Murat Corlu. All rights reserved.
//

import SwiftUI
import UIKit

private let dateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.dateTimeStyle = .named
    formatter.unitsStyle = .full
    return formatter
}()

struct ContentView: View {
    @Environment(\.managedObjectContext)
    var viewContext
 
    @State var addListModal:Bool = false

    var body: some View {
        NavigationView {
            MasterView()
                .navigationBarTitle(Text("Boring Tasks"))
                .navigationBarItems(
                    leading: EditButton()
                )
            Text("Please select/create a list to start")
        }.navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}
    
struct MasterView: View {
    @FetchRequest(
        entity: TaskList.entity(),
        sortDescriptors: [],
        animation: .default)
    var lists: FetchedResults<TaskList>

    @Environment(\.managedObjectContext)
    var viewContext

    @State var addListModal:Bool = false

    var body: some View {
        VStack {
            List {
                ForEach(lists, id: \.self) { list in
                    NavigationLink(
                        destination: DetailView(taskList: list)
                    ) {
                        Text(list.title ?? "Unknown")
                    }
                }.onDelete(perform: { indices in
                    indices.forEach { self.viewContext.delete(self.lists[$0]) }
                    
                    do {
                       try self.viewContext.save()
                    } catch {
                        print("error")
                    }
                })
            }
            HStack {
                Spacer()
                Button(action: {
                    self.addListModal = true
                }) {
                    Text("Add List")
                }.sheet(isPresented: $addListModal, content: {
                    ListEditView(closeAction: {
                        self.addListModal = false
                    }, doneAction: { title in
                        let newList = TaskList(context: self.viewContext)
                        newList.title = title
                        
                        do {
                            try self.viewContext.save()
                        } catch {
                            print("errorrrrrrrr")
                        }
                        
                        self.addListModal = false
                    })
                })
            }.padding()
        }.listStyle(GroupedListStyle())
    }
}


struct DetailView: View {
    @Environment(\.managedObjectContext)
    var viewContext

    var fetchRequest: FetchRequest<TaskItem>
    
    var items: FetchedResults<TaskItem>{
        fetchRequest.wrappedValue
    }
    
    @State private var showPopover: Bool = false

    @State var isModal: Bool = false
    
    var taskList: TaskList

    init(taskList: TaskList) {
        self.taskList = taskList
        
        fetchRequest = FetchRequest<TaskItem>(
            entity: TaskItem.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "list == %@", taskList)
        )
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(items, id: \.self) { item in
                    VStack {
                        HStack {
                            Text(item.title!)
                            Text("\(item.due!, formatter: dateFormatter)")
                                .foregroundColor(item.due! < Date() ? .red : .blue)
                            Spacer()
                        }
                        HStack {
                            ForEach(item.history, id: \.self) { activity in
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 10, height: 10, alignment: .leading)
                                    .foregroundColor(activity.type == "done" ? .blue : .gray)
                            }
                            Spacer()
                        }
                    }.contextMenu {
                        Button(action: {
                            let newActivity = TaskActivity(context: self.viewContext)
                            newActivity.date = Date()
                            newActivity.item = item
                            newActivity.type = "done"
                            newActivity.score = item.score
                            
                            let periodStr = item.period!
                            let period = Int(periodStr.replacingOccurrences(of: "D", with: ""))
                            
                            item.due = Calendar.current.date(byAdding: .day, value: period ?? 1, to: item.due!)!
                            
                            do {
                                try self.viewContext.save()
                            } catch {
                                print("error when set done")
                            }
                        }) {
                            HStack {
                                Text("Done")
                                Image(systemName: "checkmark.circle")
                            }
                        }
                        Button(action: {
                            let newActivity = TaskActivity(context: self.viewContext)
                            newActivity.date = Date()
                            newActivity.item = item
                            newActivity.type = "skip"
                            newActivity.score = 0
                            
                            let periodStr = item.period!
                            let period = Int(periodStr.replacingOccurrences(of: "D", with: ""))
                            
                            item.due = Calendar.current.date(byAdding: .day, value: period ?? 1, to: item.due!)!
                            
                            do {
                                try self.viewContext.save()
                            } catch {
                                print("error when set done")
                            }
                        }) {
                            HStack {
                                Text("Skip")
                                Image(systemName: "chevron.right.2")
                            }
                        }
                    }
                }.onDelete(perform: { indices in
                    indices.forEach { self.viewContext.delete(self.items[$0]) }
                    
                    do {
                       try self.viewContext.save()
                    } catch {
                        print("error")
                    }
                })
            }
            HStack {
                Spacer()
                Button(
                    action: {
                        self.isModal = true
                    }
                ) {
                    Text("Add Task")
                }.sheet(isPresented: $isModal, content: {
                    ItemEditView(closeAction: {
                        self.isModal = false
                    }, doneAction: { title, period in
                        let newList = TaskItem(context: self.viewContext)
                        newList.title = title
                        newList.list = self.taskList
                        newList.period = "\(period)D"
                        newList.due = Calendar.current.date(byAdding: .day, value: period, to: Date())!
                        
                        do {
                            try self.viewContext.save()
                        } catch {
                            print("errorrrrrrrr")
                        }
                        
                        self.isModal = false
                    })
                })
            }.padding()
        }

        .listStyle(GroupedListStyle())

        .navigationBarTitle(Text(taskList.title!))
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return ContentView().environment(\.managedObjectContext, context)
    }
}
